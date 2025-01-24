#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 <main_command> --during <inform_command> \\"
    echo "          [--on-succeed <success_command>] [--on-fail <failover_command>] \\"
    echo "          [--delay <seconds>] [--max-attempts <number>]"
    echo ""
    echo "Options:"
    echo "  --during         The command/function to run while the main command is running."
    echo "  --on-succeed     The command/function to run if the main command succeeds (optional)."
    echo "  --on-fail        The command/function to run if the main command fails (optional)."
    echo "  --delay          The delay (in seconds) between retries for the failover command (default: 1)."
    echo "  --max-attempts   The maximum number of retry attempts for the failover command (default: 3)."
    echo ""
    echo "Examples:"
    echo "  1. Run a long command with a 'during' command:"
    echo "     $0 'sleep 2' --during 'echo \"Main command is running...\"'"
    echo ""
    echo "  2. Simulate success with a callback:"
    echo "     $0 'sleep 2 && true' \\"
    echo "         --during 'echo \"Main command is running...\"' \\"
    echo "         --on-succeed 'echo \"Success!\"'"
    echo ""
    echo "  3. Simulate failure with retries:"
    echo "     $0 'sleep 2 && false' \\"
    echo "         --during 'echo \"Main command is running...\"' \\"
    echo "         --on-fail 'echo \"Failure!\"' \\"
    echo "         --delay 2 --max-attempts 5"
    exit 1
}

# Function to parse arguments
parse_arguments() {
    # Default values for optional arguments
    DELAY=1
    MAX_ATTEMPTS=3

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --during)
            DURING_CMD="$2"
            shift 2
            ;;
        --on-succeed)
            ON_SUCCEED_CMD="$2"
            shift 2
            ;;
        --on-fail)
            ON_FAIL_CMD="$2"
            shift 2
            ;;
        --delay)
            DELAY="$2"
            shift 2
            ;;
        --max-attempts)
            MAX_ATTEMPTS="$2"
            shift 2
            ;;
        -h | --help)
            show_help
            ;;
        *)
            MAIN_CMD="$1"
            shift
            ;;
        esac
    done

    # Validate required arguments
    if [ -z "$MAIN_CMD" ] || [ -z "$DURING_CMD" ]; then
        echo "Error: <main_command> and --during are required." >&2
        echo ""
        show_help
    fi
}

# Function to execute a command or function
execute() {
    local cmd="$1"
    if declare -f "$cmd" >/dev/null; then
        "$cmd"
    else
        eval "$cmd"
    fi
}

# Function to retry a command with delay
retry_with_delay() {
    local cmd="$1"
    local delay="$2"
    local max_attempts="$3"
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts:"
        if execute "$cmd"; then
            return 0 # Success
        fi
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            echo "Retrying in $delay seconds..."
            sleep "$delay"
        fi
    done

    return 1 # Failure after all attempts
}

# Main function
task_orchestrator() {
    parse_arguments "$@"

    # Run the main command in the background
    execute "$MAIN_CMD" &
    MAIN_PID=$!

    # Run the "during" command
    execute "$DURING_CMD" &
    DURING_PID=$!

    # Wait for the main command to finish
    wait $MAIN_PID
    MAIN_STATUS=$?

    # Clean up the "during" command
    kill $DURING_PID 2>/dev/null

    # Handle the main command's exit status
    if [ $MAIN_STATUS -eq 0 ]; then
        if [ -n "$ON_SUCCEED_CMD" ]; then
            if ! execute "$ON_SUCCEED_CMD"; then
                echo "Warning: --on-succeed command failed."
                if [ -n "$ON_FAIL_CMD" ]; then
                    echo "Attempting failover command after --on-succeed failure..."
                    if retry_with_delay "$ON_FAIL_CMD" "$DELAY" "$MAX_ATTEMPTS"; then
                        exit 0 # Exit with success status if failover succeeds
                    else
                        exit 1 # Exit with failure status if failover fails
                    fi
                else
                    exit 0 # Exit with success status (main command succeeded, --on-succeed failed, no --on-fail)
                fi
            fi
        fi
        exit 0 # Exit with success status (main command succeeded)
    else
        if [ -n "$ON_FAIL_CMD" ]; then
            echo "Main command failed. Attempting failover command..."
            if retry_with_delay "$ON_FAIL_CMD" "$DELAY" "$MAX_ATTEMPTS"; then
                exit 0 # Exit with success status if failover succeeds
            else
                exit 1 # Exit with failure status if failover fails
            fi
        else
            exit $MAIN_STATUS # Exit with main command's status if no failover command
        fi
    fi
}

# Call the main function with all arguments
task_orchestrator "$@"

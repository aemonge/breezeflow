#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 <main_command> [-w|--while <inform_command>]"
    echo "          [-s|--succeed <success_command>] [-f|--fail <failover_command>]"
    echo "          [--delay <seconds>] [--max-attempts <number>] [-v|--verbose]"
    echo ""
    echo "Options:"
    echo "  -w, --while      The command/function to run while the main command is running (optional)."
    echo "  -s, --succeed    The command/function to run if the main command succeeds (optional)."
    echo "  -f, --fail       The command/function to run if the main command fails (optional)."
    echo "  --delay          The delay (in seconds) between retries for the failover command (default: 1)."
    echo "  --max-attempts   The maximum number of retry attempts for the failover command (default: 3)."
    echo "  -v, --verbose    Enable verbose output (optional)."
    echo ""
    echo "Examples:"
    echo "  1. Run a long command without a 'while' command:"
    echo "     $0 'sleep 2'"
    echo ""
    echo "  2. Run a command with a 'while' command to monitor progress:"
    echo "     $0 'sleep 5' -w 'echo \"Main command is running...\"'"
    echo ""
    echo "  3. Simulate success with a callback:"
    echo "     $0 'sleep 2 && true' -s 'echo \"Success!\"'"
    echo ""
    echo "  4. Simulate failure with retries:"
    echo "     $0 'sleep 2 && false' -f 'echo \"Failure!\"' \\"
    echo "         --delay 2 --max-attempts 5"
    echo ""
    echo "  5. Combine all options:"
    echo "     $0 'sleep 5' -w 'echo \"Monitoring...\"' \\"
    echo "         -s 'echo \"Done!\"' -f 'echo \"Failed!\"' \\"
    echo "         --delay 1 --max-attempts 3"
    exit 1
}

# Function to parse arguments
parse_arguments() {
    # Default values for optional arguments
    DELAY=1
    MAX_ATTEMPTS=3
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -w | --while)
            DURING_CMD="$2"
            shift 2
            ;;
        -s | --succeed)
            ON_SUCCEED_CMD="$2"
            shift 2
            ;;
        -f | --fail)
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
        -v | --verbose)
            VERBOSE=true
            shift
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
    if [ -z "$MAIN_CMD" ]; then
        echo "Error: <main_command> is required." >&2
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
        if $VERBOSE; then
            echo "Attempt $attempt of $max_attempts:"
        fi
        if execute "$cmd"; then
            return 0 # Success
        fi
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            if $VERBOSE; then
                echo "Retrying in $delay seconds..."
            fi
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

    # Run the "while" command with retries (if provided)
    if [ -n "$DURING_CMD" ]; then
        if ! retry_with_delay "$DURING_CMD" "$DELAY" "$MAX_ATTEMPTS"; then
            echo "Error: --while command failed after retries."
            exit 1
        fi
    fi

    # Wait for the main command to finish
    wait $MAIN_PID
    MAIN_STATUS=$?

    # Handle the main command's exit status
    if [ $MAIN_STATUS -eq 0 ]; then
        if [ -n "$ON_SUCCEED_CMD" ]; then
            if ! retry_with_delay "$ON_SUCCEED_CMD" "$DELAY" "$MAX_ATTEMPTS"; then
                echo "Error: --succeed command failed after retries."
                exit 1
            fi
        fi
        exit 0 # Exit with success status (main command succeeded)
    else
        if [ -n "$ON_FAIL_CMD" ]; then
            if ! retry_with_delay "$ON_FAIL_CMD" "$DELAY" "$MAX_ATTEMPTS"; then
                echo "Error: --fail command failed after retries."
                exit 1
            fi
        else
            exit $MAIN_STATUS # Exit with main command's status if no failover command
        fi
    fi
}

# Call the main function with all arguments
task_orchestrator "$@"

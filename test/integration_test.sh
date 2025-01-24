#!/bin/bash

CMD="./src/breezeflow.sh"
MAIN_CMD="sleep 2"
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

run_test() {
    local description=$1
    local command=$2
    local expected_exit_code=${3:-0} # Default to 0 if not provided
    echo "----------------------------------------"
    echo -e "${CYAN}Running test: $description ${NC}"
    echo "Command: $command"
    eval $command
    local exit_status=$?
    if [ "$exit_status" -eq "$expected_exit_code" ]; then
        echo -e "${GREEN}Test PASSED${NC}"
    else
        echo -e "${RED}Test FAILED (expected exit code: $expected_exit_code, got: $exit_status)${NC}"
        exit 1
    fi
}

fail_n_times() {
    local fail_count="$1"
    if [ -f /tmp/fail_count.txt ]; then
        current_count=$(cat /tmp/fail_count.txt)
    else
        current_count=0
    fi

    if [ "$current_count" -lt "$fail_count" ]; then
        echo "Failing intentionally (attempt $((current_count + 1)) of $fail_count)"
        current_count=$((current_count + 1))
        echo "$current_count" >/tmp/fail_count.txt
        return 1
    else
        echo "Succeeding after $fail_count failures"
        rm -f /tmp/fail_count.txt
        return 0
    fi
}
export -f fail_n_times

# Test 1: Basic usage with success
run_test "49: Basic success" "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\"'"

# Test 2: Basic usage with failure
run_test "54: Basic failure" "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'echo \"Failure!\"'"

# Test 3: Simulate --on-fail failing 4 times (within max attempts)
rm -f /tmp/fail_count.txt
run_test "60: --on-fail fails 4 times (within max attempts)" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'fail_n_times 4' --delay 1 --max-attempts 5"

# Test 4: Simulate --on-fail failing more times than allowed
rm -f /tmp/fail_count.txt
run_test "67: --on-fail fails more times than allowed" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'fail_n_times 6' --delay 1 --max-attempts 5" \
    1 # Expected exit code: 1 (failure)

# Test 5: Simulate --on-succeed failing
run_test "74: --on-succeed fails" "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && false'"

# Test 6: Simulate --during failing
run_test "79: --during fails" "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-succeed 'echo \"Success!\"'"

# Test 7: Simulate --during failing and --on-fail failing
run_test "84: --during fails and --on-fail fails" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-fail 'echo \"Failure!\" && false'"

# Test 8: Simulate --during failing and --on-succeed failing
run_test "90: --during fails and --on-succeed fails" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-succeed 'echo \"Success!\" && false'"

# Test 9: Simulate --on-succeed succeeding
run_test "96: --on-succeed succeeds" "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && true'"

# Test 10: Simulate --on-fail succeeding after retries
rm -f /tmp/fail_count.txt
run_test "102: --on-fail succeeds after retries" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'fail_n_times 4' --delay 1 --max-attempts 5"

# Test 11: Simulate --on-fail succeeding immediately
run_test "108: --on-fail succeeds immediately" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'echo \"Failure!\" && true'"

# Test 12: Simulate --on-succeed failing and --on-fail succeeding
run_test "114: --on-succeed fails and --on-fail succeeds" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'echo \"Failure!\" && true'"

# Test 13: Simulate --on-succeed failing and --on-fail failing
run_test "121: --on-succeed fails and --on-fail fails" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'echo \"Failure!\" && false'" \
    1 # Expected exit code: 1 (failure)

# Test 14: Simulate --on-succeed succeeding and --on-fail failing
run_test "129: --on-succeed succeeds and --on-fail fails" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && true' \
--on-fail 'echo \"Failure!\" && false'"

# Test 15: Simulate --on-succeed succeeding and --on-fail succeeding
run_test "136: --on-succeed succeeds and --on-fail succeeds" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && true' \
--on-fail 'echo \"Failure!\" && true'"

# Test 16: Simulate --on-succeed failing and --on-fail succeeding after retries
rm -f /tmp/fail_count.txt
run_test "144: --on-succeed fails and --on-fail succeeds after retries" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'fail_n_times 4' --delay 1 --max-attempts 5"

# Test 17: Simulate --on-succeed failing and --on-fail failing after retries
rm -f /tmp/fail_count.txt
run_test "152: --on-succeed fails and --on-fail fails after retries" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'fail_n_times 6' --delay 1 --max-attempts 5" \
    1 # Expected exit code: 1 (failure)

# Test 18: Simulate --on-succeed succeeding and --on-fail failing after retries
rm -f /tmp/fail_count.txt
run_test "161: --on-succeed succeeds and --on-fail fails after retries" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && true' \
--on-fail 'fail_n_times 6' --delay 1 --max-attempts 5" \
    1 # Expected exit code: 1 (failure)

# Test 19: Simulate --on-succeed succeeding and --on-fail succeeding after retries
rm -f /tmp/fail_count.txt
run_test "170: --on-succeed succeeds and --on-fail succeeds after retries" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\" && true' \
--on-fail 'fail_n_times 4' --delay 1 --max-attempts 5"

# Test 20: Simulate --during failing four times but succeeding on the fifth attempt
rm -f /tmp/fail_count.txt
run_test "178: --during fails four times but succeeds on the fifth attempt" \
    "$CMD '$MAIN_CMD && true' \
--during 'fail_n_times 4' \
--on-succeed 'echo \"Success!\"'"

# Test 21: Simulate --during failing six times (exceeding max attempts)
rm -f /tmp/fail_count.txt
run_test "185: --during fails six times (exceeding max attempts)" \
    "$CMD '$MAIN_CMD && true' \
--during 'fail_n_times 6' \
--on-succeed 'echo \"Success!\"'" \
    1 # Expected exit code: 1 (failure)

echo "All tests completed successfully."

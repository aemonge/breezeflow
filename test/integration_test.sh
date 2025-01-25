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

# Group --on-success: Tests for --on-success behavior
echo -e "${CYAN}Group --on-success: Tests for --on-success behavior${NC}"

# Test 1: --on-success succeeds when main command succeeds
run_test "Group --on-success: Test 1: --on-success succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'echo \"Success!\"'"

# Test 2: --on-success fails when main command succeeds
run_test "Group --on-success: Test 2: --on-success fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'echo \"Success!\" && false'" \
    1

# Test 3: --on-success succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --on-success: Test 3: --on-success succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 4: --on-success fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --on-success: Test 4: --on-success fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --on-fail: Tests for --on-fail behavior
echo -e "${CYAN}Group --on-fail: Tests for --on-fail behavior${NC}"

# Test 5: --on-fail succeeds when main command fails
run_test "Group --on-fail: Test 5: --on-fail succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--on-fail 'echo \"Failure!\" && true'"

# Test 6: --on-fail fails when main command fails
run_test "Group --on-fail: Test 6: --on-fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && false' \
--on-fail 'echo \"Failure!\" && false'" \
    1

# Test 7: --on-fail succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --on-fail: Test 7: --on-fail succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--on-fail 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 8: --on-fail fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --on-fail: Test 8: --on-fail fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && false' \
--on-fail 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --during: Tests for --during behavior
echo -e "${CYAN}Group --during: Tests for --during behavior${NC}"

# Test 9: --during succeeds when main command succeeds
run_test "Group --during: Test 9: --during succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"'"

# Test 10: --during fails when main command succeeds
run_test "Group --during: Test 10: --during fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false'" \
    1

# Test 11: --during succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --during: Test 11: --during succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--during 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 12: --during fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --during: Test 12: --during fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --on-success and --on-fail: Tests for combined behavior
echo -e "${CYAN}Group --on-success and --on-fail: Tests for combined behavior${NC}"

# Test 13: --on-success succeeds and --on-fail fails (ignored)
run_test "Group --on-success and --on-fail: Test 13: --on-success succeeds and --on-fail fails => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'echo \"Success!\" && true' \
--on-fail 'echo \"Failure!\" && false'"

# Test 14: --on-success fails and --on-fail succeeds
run_test "Group --on-success and --on-fail: Test 14: --on-success fails and --on-fail succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'echo \"Failure!\" && true'" \
    1

# Test 15: --on-success fails and --on-fail fails
run_test "Group --on-success and --on-fail: Test 15: --on-success fails and --on-fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--on-succeed 'echo \"Success!\" && false' \
--on-fail 'echo \"Failure!\" && false'" \
    1

# Group --during and --on-fail: Tests for combined behavior
echo -e "${CYAN}Group --during and --on-fail: Tests for combined behavior${NC}"

# Test 16: --during fails and --on-fail succeeds
run_test "Group --during and --on-fail: Test 16: --during fails and --on-fail succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-fail 'echo \"Failure!\" && true'" \
    1

# Test 17: --during fails and --on-fail fails
run_test "Group --during and --on-fail: Test 17: --during fails and --on-fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-fail 'echo \"Failure!\" && false'" \
    1

# Group --during and --on-success: Tests for combined behavior
echo -e "${CYAN}Group --during and --on-success: Tests for combined behavior${NC}"

# Test 18: --during fails and --on-success succeeds
run_test "Group --during and --on-success: Test 18: --during fails and --on-success succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-succeed 'echo \"Success!\" && true'" \
    1

# Test 19: --during fails and --on-success fails
run_test "Group --during and --on-success: Test 19: --during fails and --on-success fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\" && false' \
--on-succeed 'echo \"Success!\" && false'" \
    1

# Group Race Conditions: Tests for race conditions with --during
echo -e "${CYAN}Group Race Conditions: Tests for race conditions with --during${NC}"

# Test 20: Race condition with --during and --on-success
run_test "Group Race Conditions: Test 20: Race condition with --during and --on-success => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--during 'echo \"Main command is running...\"' \
--on-succeed 'echo \"Success!\"'"

# Test 21: Race condition with --during and --on-fail
run_test "Group Race Conditions: Test 21: Race condition with --during and --on-fail => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--during 'echo \"Main command is running...\"' \
--on-fail 'echo \"Failure!\" && true'"

echo "All tests completed successfully."

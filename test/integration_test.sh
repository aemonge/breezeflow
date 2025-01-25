#!/bin/bash

CMD="./src/breezeflow.sh"
MAIN_CMD="sleep 2"
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE_GRAY='\033[38;5;67m'
NC='\033[0m' # No Color

run_test() {
    local description=$1
    local command=$2
    local expected_exit_code=${3:-0} # Default to 0 if not provided
    echo "----------------------------------------"
    echo -e "${CYAN}Running test: $description ${NC}"
    echo -e "Command: ${BLUE_GRAY}$command${NC}"
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

# Group --success: Tests for --success behavior
echo -e "${CYAN}Group --success: Tests for --success behavior${NC}"

# Test 1: --success succeeds when main command succeeds
run_test "Group --success: Test 1: --success succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'echo \"Success!\"'"

# Test 2: --success fails when main command succeeds
run_test "Group --success: Test 2: --success fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'echo \"Success!\" && false'" \
    1

# Test 3: --success succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --success: Test 3: --success succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 4: --success fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --success: Test 4: --success fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --fail: Tests for --fail behavior
echo -e "${CYAN}Group --fail: Tests for --fail behavior${NC}"

# Test 5: --fail succeeds when main command fails
run_test "Group --fail: Test 5: --fail succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--fail 'echo \"Failure!\" && true'"

# Test 6: --fail fails when main command fails
run_test "Group --fail: Test 6: --fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && false' \
--fail 'echo \"Failure!\" && false'" \
    1

# Test 7: --fail succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --fail: Test 7: --fail succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--fail 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 8: --fail fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --fail: Test 8: --fail fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && false' \
--fail 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --while: Tests for --while behavior
echo -e "${CYAN}Group --while: Tests for --while behavior${NC}"

# Test 9: --while succeeds when main command succeeds
run_test "Group --while: Test 9: --while succeeds => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\"'"

# Test 10: --while fails when main command succeeds
run_test "Group --while: Test 10: --while fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\" && false'" \
    1

# Test 11: --while succeeds after 4 retries (within max attempts)
rm -f /tmp/fail_count.txt
run_test "Group --while: Test 11: --while succeeds after 4 retries => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--while 'fail_n_times 4' --max-attempts 5 --delay 1"

# Test 12: --while fails after exceeding max attempts
rm -f /tmp/fail_count.txt
run_test "Group --while: Test 12: --while fails after exceeding max attempts => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'fail_n_times 6' --max-attempts 5 --delay 1" \
    1

# Group --success and --fail: Tests for combined behavior
echo -e "${CYAN}Group --success and --fail: Tests for combined behavior${NC}"

# Test 13: --success succeeds and --fail fails (ignored)
run_test "Group --success and --fail: Test 13: --success succeeds and --fail fails => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'echo \"Success!\" && true' \
--fail 'echo \"Failure!\" && false'"

# Test 14: --success fails and --fail succeeds
run_test "Group --success and --fail: Test 14: --success fails and --fail succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'echo \"Success!\" && false' \
--fail 'echo \"Failure!\" && true'" \
    1

# Test 15: --success fails and --fail fails
run_test "Group --success and --fail: Test 15: --success fails and --fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--succeed 'echo \"Success!\" && false' \
--fail 'echo \"Failure!\" && false'" \
    1

# Group --while and --fail: Tests for combined behavior
echo -e "${CYAN}Group --while and --fail: Tests for combined behavior${NC}"

# Test 16: --while fails and --fail succeeds
run_test "Group --while and --fail: Test 16: --while fails and --fail succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\" && false' \
--fail 'echo \"Failure!\" && true'" \
    1

# Test 17: --while fails and --fail fails
run_test "Group --while and --fail: Test 17: --while fails and --fail fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\" && false' \
--fail 'echo \"Failure!\" && false'" \
    1

# Group --while and --success: Tests for combined behavior
echo -e "${CYAN}Group --while and --success: Tests for combined behavior${NC}"

# Test 18: --while fails and --success succeeds
run_test "Group --while and --success: Test 18: --while fails and --success succeeds => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\" && false' \
--succeed 'echo \"Success!\" && true'" \
    1

# Test 19: --while fails and --success fails
run_test "Group --while and --success: Test 19: --while fails and --success fails => Expected exit code: 1" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\" && false' \
--succeed 'echo \"Success!\" && false'" \
    1

# Group Race Conditions: Tests for race conditions with --while
echo -e "${CYAN}Group Race Conditions: Tests for race conditions with --while${NC}"

# Test 20: Race condition with --while and --success
run_test "Group Race Conditions: Test 20: Race condition with --while and --success => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && true' \
--while 'echo \"Main command is running...\"' \
--succeed 'echo \"Success!\"'"

# Test 21: Race condition with --while and --fail
run_test "Group Race Conditions: Test 21: Race condition with --while and --fail => Expected exit code: 0" \
    "$CMD '$MAIN_CMD && false' \
--while 'echo \"Main command is running...\"' \
--fail 'echo \"Failure!\" && true'"

echo "All tests completed successfully."

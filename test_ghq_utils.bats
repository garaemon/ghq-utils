#!/usr/bin/env bats

# Setup and teardown
setup() {
    # Source the script to test
    source "${BATS_TEST_DIRNAME}/ghq-utils.sh"

    # Create temporary directory for testing
    export TEST_GHQ_ROOT="${BATS_TEST_TMPDIR}/ghq"
    mkdir -p "${TEST_GHQ_ROOT}"

    # Create mock repository structure
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/user1/ghq-utils"
    mkdir -p "${TEST_GHQ_ROOT}/gitlab.com/garaemon/project1"

    # Save original directory
    export ORIGINAL_DIR="${PWD}"

    # Mock ghq command
    ghq() {
        case "$1" in
            root)
                echo "${TEST_GHQ_ROOT}"
                return 0
                ;;
            list)
                cat <<EOF
github.com/garaemon/ghq-utils
github.com/garaemon/dotfiles
github.com/user1/ghq-utils
gitlab.com/garaemon/project1
EOF
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    export -f ghq
}

teardown() {
    # Return to original directory
    cd "${ORIGINAL_DIR}" || true
    # Clean up temporary directory
    rm -rf "${TEST_GHQ_ROOT}"
}

# Test: ghq-cd with no arguments should navigate to GHQ_ROOT
@test "ghq-cd with no arguments navigates to GHQ_ROOT" {
    ghq-cd
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}" ]
}

# Test: ghq-cd with unique repository name
@test "ghq-cd with unique repository name succeeds" {
    ghq-cd dotfiles
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles" ]
}

# Test: ghq-cd with ambiguous repository name
@test "ghq-cd with ambiguous repository name fails" {
    run ghq-cd ghq-utils
    [ "$status" -eq 1 ]
    [[ "$output" == *"Multiple repositories found"* ]]
}

# Test: ghq-cd with account/repository format
@test "ghq-cd with account/repository format succeeds" {
    ghq-cd garaemon/ghq-utils
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils" ]
}

# Test: ghq-cd with full path format
@test "ghq-cd with full path format succeeds" {
    ghq-cd github.com/garaemon/ghq-utils
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils" ]
}

# Test: ghq-cd with non-existent repository
@test "ghq-cd with non-existent repository fails" {
    run ghq-cd nonexistent-repo
    [ "$status" -eq 1 ]
    [[ "$output" == *"No repository found"* ]]
}

# Test: ghq-cd with non-existent full path
@test "ghq-cd with non-existent full path fails" {
    run ghq-cd github.com/user/nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

# Test: ghq-cd with invalid path format (too many slashes)
@test "ghq-cd with invalid path format fails" {
    run ghq-cd github.com/garaemon/ghq-utils/extra
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid path format"* ]]
}

# Test: _ghq_cd_get_candidates generates all completion formats
@test "_ghq_cd_get_candidates generates completion candidates" {
    run _ghq_cd_get_candidates
    [ "$status" -eq 0 ]

    # Check for full path
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]

    # Check for account/repo format
    [[ "$output" == *"garaemon/ghq-utils"* ]]

    # Check for repository name only
    [[ "$output" == *"ghq-utils"* ]]
    [[ "$output" == *"dotfiles"* ]]
    [[ "$output" == *"project1"* ]]
}

# Test: _ghq_cd_get_candidates with no repositories
@test "_ghq_cd_get_candidates with empty ghq list" {
    # Override ghq mock to return empty list
    ghq() {
        case "$1" in
            root)
                echo "${TEST_GHQ_ROOT}"
                return 0
                ;;
            list)
                echo ""
                return 0
                ;;
        esac
    }
    export -f ghq

    run _ghq_cd_get_candidates
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# Test: ghq-cd when ghq root command fails
@test "ghq-cd fails when ghq root command fails" {
    # Override ghq mock to fail
    ghq() {
        return 1
    }
    export -f ghq

    run ghq-cd
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to get ghq root"* ]]
}

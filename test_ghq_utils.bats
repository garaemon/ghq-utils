#!/usr/bin/env bats

# Setup and teardown
setup() {
    # Source the script to test
    source "${BATS_TEST_DIRNAME}/ghq-utils.sh"

    # Create temporary directory for testing
    export TEST_GHQ_ROOT="${BATS_TEST_TMPDIR}/ghq"
    mkdir -p "${TEST_GHQ_ROOT}"

    # Create mock repository structure with git repositories
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/user1/ghq-utils"
    mkdir -p "${TEST_GHQ_ROOT}/gitlab.com/garaemon/project1"

    # Initialize git repositories for ghq-pull tests with bare repositories as remotes
    mkdir -p "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/ghq-utils.git"
    mkdir -p "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/dotfiles.git"
    mkdir -p "${TEST_GHQ_ROOT}/.remotes/github.com/user1/ghq-utils.git"
    mkdir -p "${TEST_GHQ_ROOT}/.remotes/gitlab.com/garaemon/project1.git"

    (cd "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/ghq-utils.git" && git init --bare -q)
    (cd "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/dotfiles.git" && git init --bare -q)
    (cd "${TEST_GHQ_ROOT}/.remotes/github.com/user1/ghq-utils.git" && git init --bare -q)
    (cd "${TEST_GHQ_ROOT}/.remotes/gitlab.com/garaemon/project1.git" && git init --bare -q)

    (cd "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils" && git init -q && git config user.email "test@test.com" && git config user.name "Test User" && touch README.md && git add README.md && git commit -q -m "initial" && git remote add origin "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/ghq-utils.git" && git push -u -q origin main 2>/dev/null || git push -u -q origin master 2>/dev/null)
    (cd "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles" && git init -q && git config user.email "test@test.com" && git config user.name "Test User" && touch .bashrc && git add .bashrc && git commit -q -m "initial" && git remote add origin "${TEST_GHQ_ROOT}/.remotes/github.com/garaemon/dotfiles.git" && git push -u -q origin main 2>/dev/null || git push -u -q origin master 2>/dev/null)
    (cd "${TEST_GHQ_ROOT}/github.com/user1/ghq-utils" && git init -q && git config user.email "test@test.com" && git config user.name "Test User" && touch README.md && git add README.md && git commit -q -m "initial" && git remote add origin "${TEST_GHQ_ROOT}/.remotes/github.com/user1/ghq-utils.git" && git push -u -q origin main 2>/dev/null || git push -u -q origin master 2>/dev/null)
    (cd "${TEST_GHQ_ROOT}/gitlab.com/garaemon/project1" && git init -q && git config user.email "test@test.com" && git config user.name "Test User" && touch main.go && git add main.go && git commit -q -m "initial" && git remote add origin "${TEST_GHQ_ROOT}/.remotes/gitlab.com/garaemon/project1.git" && git push -u -q origin main 2>/dev/null || git push -u -q origin master 2>/dev/null)

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

# ===== ghq-pull tests =====

# Test: ghq-pull with no arguments in repository
@test "ghq-pull with no arguments in repository succeeds" {
    cd "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils"
    run ghq-pull
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pulling current repository"* ]]
}

# Test: ghq-pull with no arguments outside GHQ_ROOT fails
@test "ghq-pull with no arguments outside GHQ_ROOT fails" {
    cd /tmp
    run ghq-pull
    [ "$status" -eq 1 ]
    [[ "$output" == *"not under GHQ_ROOT"* ]]
}

# Test: ghq-pull with no arguments in non-git directory fails
@test "ghq-pull with no arguments in non-git directory fails" {
    mkdir -p "${TEST_GHQ_ROOT}/github.com/test/nonrepo"
    cd "${TEST_GHQ_ROOT}/github.com/test/nonrepo"
    run ghq-pull
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a git repository"* ]]
}

# Test: ghq-pull with unique repository name
@test "ghq-pull with unique repository name succeeds" {
    run ghq-pull dotfiles
    [ "$status" -eq 0 ]
    [[ "$output" == *"dotfiles"* ]]
    [[ "$output" == *"Summary"* ]]
}

# Test: ghq-pull with ambiguous repository name pulls all matches
@test "ghq-pull with ambiguous repository name pulls all matches" {
    run ghq-pull ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 2 repository(ies)"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/user1/ghq-utils"* ]]
}

# Test: ghq-pull with account/repository format
@test "ghq-pull with account/repository format succeeds" {
    run ghq-pull garaemon/ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"Summary"* ]]
}

# Test: ghq-pull with full path format
@test "ghq-pull with full path format succeeds" {
    run ghq-pull github.com/garaemon/ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"Summary"* ]]
}

# Test: ghq-pull with account name pulls all repos in account
@test "ghq-pull with account name pulls all repos in account" {
    run ghq-pull garaemon
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 3 repository(ies)"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/garaemon/dotfiles"* ]]
    [[ "$output" == *"gitlab.com/garaemon/project1"* ]]
}

# Test: ghq-pull with hostname pulls all repos in hostname
@test "ghq-pull with hostname pulls all repos in hostname" {
    run ghq-pull github.com
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 3 repository(ies)"* ]]
}

# Test: ghq-pull with hostname/account pulls all repos in account
@test "ghq-pull with hostname/account pulls all repos in account" {
    run ghq-pull github.com/garaemon
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 2 repository(ies)"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/garaemon/dotfiles"* ]]
}

# Test: ghq-pull --all pulls all repositories
@test "ghq-pull --all pulls all repositories" {
    run ghq-pull --all
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pulling all repositories"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/garaemon/dotfiles"* ]]
    [[ "$output" == *"github.com/user1/ghq-utils"* ]]
    [[ "$output" == *"gitlab.com/garaemon/project1"* ]]
}

# Test: ghq-pull with non-existent repository fails
@test "ghq-pull with non-existent repository fails" {
    run ghq-pull nonexistent-repo
    [ "$status" -eq 1 ]
    [[ "$output" == *"No repository found"* ]]
}

# Test: ghq-pull with invalid path format fails
@test "ghq-pull with invalid path format fails" {
    run ghq-pull github.com/garaemon/ghq-utils/extra
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid path format"* ]]
}

# Test: ghq-pull with non-git directory fails
@test "ghq-pull with non-git directory reports error" {
    mkdir -p "${TEST_GHQ_ROOT}/github.com/test/nongit"
    # Override ghq list to include non-git directory
    ghq() {
        case "$1" in
            root)
                echo "${TEST_GHQ_ROOT}"
                return 0
                ;;
            list)
                cat <<EOF
github.com/test/nongit
EOF
                return 0
                ;;
        esac
    }
    export -f ghq

    run ghq-pull nongit
    [ "$status" -eq 1 ]
    [[ "$output" == *"Not a git repository"* ]]
}

# Test: _ghq_pull_get_candidates generates completion candidates
@test "_ghq_pull_get_candidates generates completion candidates" {
    run _ghq_pull_get_candidates
    [ "$status" -eq 0 ]

    # Check for --all option
    [[ "$output" == *"--all"* ]]

    # Check for full path
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]

    # Check for account/repo format
    [[ "$output" == *"garaemon/ghq-utils"* ]]

    # Check for repository name only
    [[ "$output" == *"ghq-utils"* ]]
    [[ "$output" == *"dotfiles"* ]]

    # Check for hostname
    [[ "$output" == *"github.com"* ]]
    [[ "$output" == *"gitlab.com"* ]]

    # Check for hostname/account
    [[ "$output" == *"github.com/garaemon"* ]]
}

# Test: _ghq_pull_get_candidates with empty ghq list
@test "_ghq_pull_get_candidates with empty ghq list returns only --all" {
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

    run _ghq_pull_get_candidates
    [ "$status" -eq 0 ]
    [[ "$output" == *"--all"* ]]
}

# Test: ghq-pull fails when ghq root command fails
@test "ghq-pull fails when ghq root command fails" {
    # Override ghq mock to fail
    ghq() {
        return 1
    }
    export -f ghq

    run ghq-pull
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to get ghq root"* ]]
}

# Test: ghq-pull with trailing slash in account name
@test "ghq-pull with trailing slash in account name succeeds" {
    run ghq-pull garaemon/
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 3 repository(ies)"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/garaemon/dotfiles"* ]]
    [[ "$output" == *"gitlab.com/garaemon/project1"* ]]
}

# Test: ghq-pull with trailing slash in account/repository format
@test "ghq-pull with trailing slash in account/repository format succeeds" {
    run ghq-pull garaemon/ghq-utils/
    [ "$status" -eq 0 ]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"Summary"* ]]
}

# Test: ghq-pull with trailing slash in hostname/account format
@test "ghq-pull with trailing slash in hostname/account format succeeds" {
    run ghq-pull github.com/garaemon/
    [ "$status" -eq 0 ]
    [[ "$output" == *"Found 2 repository(ies)"* ]]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"github.com/garaemon/dotfiles"* ]]
}

# Test: ghq-pull with trailing slash in full path format
@test "ghq-pull with trailing slash in full path format succeeds" {
    run ghq-pull github.com/garaemon/ghq-utils/
    [ "$status" -eq 0 ]
    [[ "$output" == *"github.com/garaemon/ghq-utils"* ]]
    [[ "$output" == *"Summary"* ]]
}

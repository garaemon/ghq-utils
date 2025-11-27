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

    # Create subdirectories for testing
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils/.github/workflows"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils/src/utils"
    mkdir -p "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles/.config/nvim"

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

# Test: ghq-cd with subdirectory in full path format
@test "ghq-cd with subdirectory in full path format succeeds" {
    ghq-cd github.com/garaemon/ghq-utils/.github/workflows
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils/.github/workflows" ]
}

# Test: ghq-cd with subdirectory using repository name only
@test "ghq-cd with subdirectory using repository name only succeeds" {
    ghq-cd dotfiles/.config/nvim
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/dotfiles/.config/nvim" ]
}

# Test: ghq-cd with subdirectory using account/repository format
@test "ghq-cd with subdirectory using account/repository format succeeds" {
    ghq-cd garaemon/ghq-utils/src/utils
    [ "$?" -eq 0 ]
    [ "${PWD}" = "${TEST_GHQ_ROOT}/github.com/garaemon/ghq-utils/src/utils" ]
}

# Test: ghq-cd with non-existent subdirectory fails
@test "ghq-cd with non-existent subdirectory fails" {
    run ghq-cd dotfiles/nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
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

# Test: ghq-pull with subdirectory path fails (not supported for ghq-pull)
@test "ghq-pull with subdirectory path fails" {
    run ghq-pull github.com/garaemon/ghq-utils/.github/workflows
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

# ===== ghq-info tests =====

# Test: ghq-info with no arguments lists all repos
@test "ghq-info with no arguments lists all repos" {
    run ghq-info
    [ "$status" -eq 0 ]
    [[ "$output" =~ garaemon/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/ghq-utils ]]
    [[ "$output" =~ garaemon/dotfiles[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/dotfiles ]]
    [[ "$output" =~ user1/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/user1/ghq-utils ]]
    [[ "$output" =~ garaemon/project1[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/gitlab.com/garaemon/project1 ]]
}

# Test: ghq-info with unique repository name
@test "ghq-info with unique repository name succeeds" {
    run ghq-info dotfiles
    [ "$status" -eq 0 ]
    # Check output format: account/repo commit branch path
    # We expect: garaemon/dotfiles <commit> <branch> .../github.com/garaemon/dotfiles
    # commit hash is alphanumeric (hex)
    [[ "$output" =~ garaemon/dotfiles[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/dotfiles ]]
}

# Test: ghq-info with ambiguous repository name lists all
@test "ghq-info with ambiguous repository name lists all" {
    run ghq-info ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" =~ garaemon/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/ghq-utils ]]
    [[ "$output" =~ user1/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/user1/ghq-utils ]]
}

# Test: ghq-info with account name lists all repos in account
@test "ghq-info with account name lists all repos in account" {
    run ghq-info garaemon
    [ "$status" -eq 0 ]
    [[ "$output" =~ garaemon/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/ghq-utils ]]
    [[ "$output" =~ garaemon/dotfiles[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/dotfiles ]]
    [[ "$output" =~ garaemon/project1[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/gitlab.com/garaemon/project1 ]]
}

# Test: ghq-info with account/repository format
@test "ghq-info with account/repository format succeeds" {
    run ghq-info garaemon/ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" =~ garaemon/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/ghq-utils ]]
    # Should not match user1/ghq-utils
    [[ ! "$output" =~ user1/ghq-utils ]]
}

# Test: ghq-info with full path format
@test "ghq-info with full path format succeeds" {
    run ghq-info github.com/garaemon/ghq-utils
    [ "$status" -eq 0 ]
    [[ "$output" =~ garaemon/ghq-utils[[:space:]]+[0-9a-f]+[[:space:]]+(main|master)[[:space:]]+.*/github.com/garaemon/ghq-utils ]]
}

# Test: ghq-info with non-existent repository fails
@test "ghq-info with non-existent repository fails" {
    run ghq-info nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"No repository found"* ]]
}

# Test: ghq-info shows 'not-a-git-repo' for non-git directories
@test "ghq-info shows 'not-a-git-repo' for non-git directories" {
    mkdir -p "${TEST_GHQ_ROOT}/github.com/test/nongit"
    # Override ghq list to include non-git directory
    ghq() {
        case "$1" in
            root)
                echo "${TEST_GHQ_ROOT}"
                return 0
                ;;
            list)
                echo "github.com/test/nongit"
                return 0
                ;;
        esac
    }
    export -f ghq

    run ghq-info nongit
    [ "$status" -eq 0 ]
    # Expect -------- for commit hash in non-git repo
    [[ "$output" =~ test/nongit[[:space:]]+--------[[:space:]]+not-a-git-repo[[:space:]]+.*/github.com/test/nongit ]]
}

# Test: _ghq_info_get_candidates generates candidates without --all
@test "_ghq_info_get_candidates generates candidates without --all" {
    run _ghq_info_get_candidates
    [ "$status" -eq 0 ]

    # Should NOT contain --all
    [[ ! "$output" == *"--all"* ]]

    # Should contain repos
    [[ "$output" == *"ghq-utils"* ]]
    [[ "$output" == *"garaemon/ghq-utils"* ]]
}

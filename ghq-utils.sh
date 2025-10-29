#!/bin/bash

# ghq-cd: Navigate to ghq-managed repository directories
#
# Usage:
#   ghq-cd [hostname/][account_name/]repository_name
#   ghq-cd
#
# Examples:
#   ghq-cd ghq-utils
#   ghq-cd garaemon/ghq-utils
#   ghq-cd github.com/garaemon/ghq-utils
#   ghq-cd  # Go to GHQ_ROOT

ghq-cd() {
    local target_path="$1"
    local ghq_root
    local matching_repos
    local repo_count

    # Get GHQ_ROOT
    if ! ghq_root=$(ghq root 2>/dev/null) || [ -z "$ghq_root" ]; then
        echo "Error: Failed to get ghq root" >&2
        return 1
    fi

    # No arguments: change to GHQ_ROOT
    if [ -z "$target_path" ]; then
        cd "$ghq_root" || return 1
        return 0
    fi

    # Count slashes in the target path
    local slash_count
    slash_count=$(echo "$target_path" | tr -cd '/' | wc -c | tr -d ' ')

    case "$slash_count" in
        0)
            # Repository name only
            matching_repos=$(ghq list | grep "/${target_path}$")
            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)

            if [ -z "$matching_repos" ]; then
                echo "Error: No repository found with name '${target_path}'" >&2
                return 1
            elif [ "$repo_count" -eq 1 ]; then
                cd "${ghq_root}/${matching_repos}" || return 1
                return 0
            else
                echo "Error: Multiple repositories found with name '${target_path}':" >&2
                while IFS= read -r repo; do
                    echo "  $repo" >&2
                done <<< "$matching_repos"
                return 1
            fi
            ;;
        1)
            # account_name/repository_name
            matching_repos=$(ghq list | grep "/${target_path}$")
            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)

            if [ -z "$matching_repos" ]; then
                echo "Error: Repository '${target_path}' not found" >&2
                return 1
            elif [ "$repo_count" -eq 1 ]; then
                cd "${ghq_root}/${matching_repos}" || return 1
                return 0
            else
                echo "Error: Multiple repositories found:" >&2
                while IFS= read -r repo; do
                    echo "  $repo" >&2
                done <<< "$matching_repos"
                return 1
            fi
            ;;
        2)
            # hostname/account_name/repository_name
            if [ -d "${ghq_root}/${target_path}" ]; then
                cd "${ghq_root}/${target_path}" || return 1
                return 0
            else
                echo "Error: Repository '${target_path}' not found" >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Invalid path format '${target_path}'" >&2
            return 1
            ;;
    esac
}

# Helper function to generate completion candidates
_ghq_cd_get_candidates() {
    local repos
    repos=$(ghq list 2>/dev/null)
    if [ -z "$repos" ]; then
        return
    fi

    local candidates=()

    # Generate all possible completion formats
    while IFS= read -r repo; do
        # Full path: hostname/account/repository
        candidates+=("$repo")

        # Extract account/repository
        candidates+=("${repo#*/}")

        # Extract repository name only
        candidates+=("$(basename "$repo")")
    done <<< "$repos"

    # Remove duplicates and print
    printf '%s\n' "${candidates[@]}" | sort -u
}

# Zsh completion function
if [ -n "$ZSH_VERSION" ]; then
    _ghq_cd() {
        local -a candidates
        while IFS= read -r line; do
            candidates+=("$line")
        done < <(_ghq_cd_get_candidates)
        _describe 'repository' candidates
    }
    compdef _ghq_cd ghq-cd
fi

# Bash completion function
if [ -n "$BASH_VERSION" ]; then
    _ghq_cd_bash() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local candidates

        candidates=$(_ghq_cd_get_candidates)
        mapfile -t COMPREPLY < <(compgen -W "$candidates" -- "$cur")
    }
    complete -F _ghq_cd_bash ghq-cd
fi

# ghq-pull: Execute git pull in ghq-managed repositories
#
# Usage:
#   ghq-pull
#   ghq-pull [hostname/][account_name/]repository_name
#   ghq-pull [hostname/]account_name
#   ghq-pull hostname
#   ghq-pull --all
#
# Examples:
#   ghq-pull                                # Pull current repository
#   ghq-pull ghq-utils                      # Pull specific repository
#   ghq-pull garaemon/ghq-utils             # Pull specific repository
#   ghq-pull github.com/garaemon/ghq-utils  # Pull specific repository
#   ghq-pull garaemon                       # Pull all repos in account
#   ghq-pull github.com/garaemon            # Pull all repos in account
#   ghq-pull github.com                     # Pull all repos in hostname
#   ghq-pull --all                          # Pull all repositories

ghq-pull() {
    local target_path="$1"
    local ghq_root
    local matching_repos
    local repo_count
    local failed_repos=()

    # Get GHQ_ROOT
    if ! ghq_root=$(ghq root 2>/dev/null) || [ -z "$ghq_root" ]; then
        echo "Error: Failed to get ghq root" >&2
        return 1
    fi

    # Handle --all flag
    if [ "$target_path" = "--all" ]; then
        matching_repos=$(ghq list)
        if [ -z "$matching_repos" ]; then
            echo "No repositories found" >&2
            return 1
        fi
        echo "Pulling all repositories..."
        _ghq_pull_execute_pull "$ghq_root" "$matching_repos"
        return $?
    fi

    # No arguments: pull current repository
    if [ -z "$target_path" ]; then
        local current_dir
        current_dir=$(pwd)
        if [[ "$current_dir" != "$ghq_root"* ]]; then
            echo "Error: Current directory is not under GHQ_ROOT" >&2
            return 1
        fi

        if [ ! -d ".git" ]; then
            echo "Error: Current directory is not a git repository" >&2
            return 1
        fi

        echo "Pulling current repository..."
        git pull
        return $?
    fi

    # Count slashes in the target path
    local slash_count
    slash_count=$(echo "$target_path" | tr -cd '/' | wc -c | tr -d ' ')

    case "$slash_count" in
        0)
            # Could be: repository_name, account_name, or hostname
            # Try to find matching repositories
            matching_repos=$(ghq list | grep "/${target_path}$")

            if [ -z "$matching_repos" ]; then
                # Try as account name or hostname
                matching_repos=$(ghq list | grep "/${target_path}/")
            fi

            if [ -z "$matching_repos" ]; then
                # Try as hostname
                matching_repos=$(ghq list | grep "^${target_path}/")
            fi

            if [ -z "$matching_repos" ]; then
                echo "Error: No repository found matching '${target_path}'" >&2
                return 1
            fi

            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)
            echo "Found ${repo_count} repository(ies) matching '${target_path}'"
            _ghq_pull_execute_pull "$ghq_root" "$matching_repos"
            return $?
            ;;
        1)
            # Could be: hostname/account_name or account_name/repository_name
            # Try account_name/repository_name first
            matching_repos=$(ghq list | grep "/${target_path}$")

            if [ -z "$matching_repos" ]; then
                # Try hostname/account_name
                matching_repos=$(ghq list | grep "^${target_path}/")
            fi

            if [ -z "$matching_repos" ]; then
                echo "Error: No repository found matching '${target_path}'" >&2
                return 1
            fi

            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)
            echo "Found ${repo_count} repository(ies) matching '${target_path}'"
            _ghq_pull_execute_pull "$ghq_root" "$matching_repos"
            return $?
            ;;
        2)
            # hostname/account_name/repository_name
            matching_repos=$(ghq list | grep "^${target_path}$")

            if [ -z "$matching_repos" ]; then
                echo "Error: Repository '${target_path}' not found" >&2
                return 1
            fi

            echo "Pulling repository '${target_path}'"
            _ghq_pull_execute_pull "$ghq_root" "$matching_repos"
            return $?
            ;;
        *)
            echo "Error: Invalid path format '${target_path}'" >&2
            return 1
            ;;
    esac
}

# Helper function to execute git pull in multiple repositories
_ghq_pull_execute_pull() {
    local ghq_root="$1"
    local repos="$2"
    local failed_repos=()
    local success_count=0
    local fail_count=0

    while IFS= read -r repo; do
        local repo_path="${ghq_root}/${repo}"
        echo ""
        echo "==> Pulling ${repo}"

        if [ ! -d "$repo_path" ]; then
            echo "Error: Directory not found: ${repo_path}" >&2
            failed_repos+=("$repo")
            ((fail_count++))
            continue
        fi

        if [ ! -d "${repo_path}/.git" ]; then
            echo "Error: Not a git repository: ${repo_path}" >&2
            failed_repos+=("$repo")
            ((fail_count++))
            continue
        fi

        if (cd "$repo_path" && git pull); then
            ((success_count++))
        else
            echo "Error: Failed to pull ${repo}" >&2
            failed_repos+=("$repo")
            ((fail_count++))
        fi
    done <<< "$repos"

    echo ""
    echo "==> Summary: ${success_count} succeeded, ${fail_count} failed"

    if [ ${#failed_repos[@]} -gt 0 ]; then
        echo "Failed repositories:"
        for repo in "${failed_repos[@]}"; do
            echo "  - $repo"
        done
        return 1
    fi

    return 0
}

# Helper function to generate completion candidates for ghq-pull
_ghq_pull_get_candidates() {
    local repos
    repos=$(ghq list 2>/dev/null)

    local candidates=()

    # Add --all option
    candidates+=("--all")

    if [ -z "$repos" ]; then
        printf '%s\n' "${candidates[@]}"
        return
    fi

    # Generate all possible completion formats
    while IFS= read -r repo; do
        # Full path: hostname/account/repository
        candidates+=("$repo")

        # Extract account/repository
        candidates+=("${repo#*/}")

        # Extract repository name only
        candidates+=("$(basename "$repo")")

        # Extract hostname
        local hostname="${repo%%/*}"
        candidates+=("$hostname")

        # Extract hostname/account
        local account_path="${repo%/*}"
        candidates+=("$account_path")
    done <<< "$repos"

    # Remove duplicates and print
    printf '%s\n' "${candidates[@]}" | sort -u
}

# Zsh completion function for ghq-pull
if [ -n "$ZSH_VERSION" ]; then
    _ghq_pull() {
        local -a candidates
        while IFS= read -r line; do
            candidates+=("$line")
        done < <(_ghq_pull_get_candidates)
        _describe 'repository' candidates
    }
    compdef _ghq_pull ghq-pull
fi

# Bash completion function for ghq-pull
if [ -n "$BASH_VERSION" ]; then
    _ghq_pull_bash() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local candidates

        candidates=$(_ghq_pull_get_candidates)
        mapfile -t COMPREPLY < <(compgen -W "$candidates" -- "$cur")
    }
    complete -F _ghq_pull_bash ghq-pull
fi

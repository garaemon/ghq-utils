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

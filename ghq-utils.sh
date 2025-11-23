#!/bin/bash

# ghq-cd: Navigate to ghq-managed repository directories
#
# Usage:
#   ghq-cd [hostname/][account_name/]repository_name[/subdirectory]
#   ghq-cd
#
# Examples:
#   ghq-cd ghq-utils
#   ghq-cd ghq-utils/.github/workflows
#   ghq-cd garaemon/ghq-utils
#   ghq-cd garaemon/ghq-utils/src
#   ghq-cd github.com/garaemon/ghq-utils
#   ghq-cd github.com/garaemon/ghq-utils/.github
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

    # Extract repository part and subdirectory part
    local repo_part
    local subdir_part=""

    case "$slash_count" in
        0)
            # Repository name only (no subdirectory)
            repo_part="$target_path"
            ;;
        1)
            # Could be: account/repo or repo/subdir
            # Try to detect if this is a valid account/repo pattern first
            matching_repos=$(ghq list | grep "/${target_path}$")
            if [ -n "$matching_repos" ]; then
                # This is account/repo pattern
                repo_part="$target_path"
            else
                # This might be repo/subdir pattern
                repo_part="${target_path%%/*}"
                subdir_part="${target_path#*/}"
            fi
            ;;
        2)
            # Could be: hostname/account/repo or account/repo/subdir or repo/subdir/subdir
            # First try hostname/account/repo pattern
            matching_repos=""
            while IFS= read -r line; do
                if [ "$line" = "$target_path" ]; then
                    matching_repos="$line"
                    break
                fi
            done < <(ghq list)

            if [ -n "$matching_repos" ]; then
                # This is hostname/account/repo pattern
                repo_part="$target_path"
            else
                # Check if first part looks like hostname (contains dot)
                local first_component="${target_path%%/*}"
                if [[ "$first_component" == *.* ]]; then
                    # Looks like hostname/account/repo but not found
                    repo_part="$target_path"
                else
                    # Check if this could be account/repo/subdir
                    local temp="${target_path#*/}"
                    local first_two_parts="${target_path%%/*}/${temp%%/*}"
                    matching_repos=$(ghq list | grep "/${first_two_parts}$")
                    if [ -n "$matching_repos" ]; then
                        # This is account/repo/subdir pattern
                        repo_part="$first_two_parts"
                        subdir_part="${temp#*/}"
                    else
                        # This might be repo/subdir/subdir pattern
                        repo_part="${target_path%%/*}"
                        subdir_part="${target_path#*/}"
                    fi
                fi
            fi
            ;;
        *)
            # 3 or more slashes: hostname/account/repo/subdir or other patterns
            # Try to extract first 3 parts as hostname/account/repo
            local first_part="${target_path%%/*}"
            local rest_after_first="${target_path#*/}"
            local second_part="${rest_after_first%%/*}"
            local rest_after_second="${rest_after_first#*/}"
            local third_part="${rest_after_second%%/*}"
            local potential_repo="${first_part}/${second_part}/${third_part}"

            matching_repos=""
            while IFS= read -r line; do
                if [ "$line" = "$potential_repo" ]; then
                    matching_repos="$line"
                    break
                fi
            done < <(ghq list)

            if [ -n "$matching_repos" ]; then
                # This is hostname/account/repo/subdir pattern
                repo_part="$potential_repo"
                subdir_part="${rest_after_second#*/}"
            else
                # Try account/repo pattern with subdirectory
                local first_two_parts="${target_path%%/*}/${rest_after_first%%/*}"
                matching_repos=$(ghq list | grep "/${first_two_parts}$")
                if [ -n "$matching_repos" ]; then
                    repo_part="$first_two_parts"
                    local temp="${target_path#*/}"
                    subdir_part="${temp#*/}"
                else
                    # Try repo pattern with subdirectory
                    repo_part="${target_path%%/*}"
                    subdir_part="${target_path#*/}"
                fi
            fi
            ;;
    esac

    # Now resolve the repository part
    local repo_slash_count
    repo_slash_count=$(echo "$repo_part" | tr -cd '/' | wc -c | tr -d ' ')

    local resolved_repo_path=""

    case "$repo_slash_count" in
        0)
            # Repository name only
            matching_repos=$(ghq list | grep "/${repo_part}$")
            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)

            if [ -z "$matching_repos" ]; then
                echo "Error: No repository found with name '${repo_part}'" >&2
                return 1
            elif [ "$repo_count" -eq 1 ]; then
                resolved_repo_path="$matching_repos"
            else
                echo "Error: Multiple repositories found with name '${repo_part}':" >&2
                while IFS= read -r repo; do
                    echo "  $repo" >&2
                done <<< "$matching_repos"
                return 1
            fi
            ;;
        1)
            # account_name/repository_name
            matching_repos=$(ghq list | grep "/${repo_part}$")
            repo_count=$(echo "$matching_repos" | grep -c '^' 2>/dev/null)

            if [ -z "$matching_repos" ]; then
                echo "Error: Repository '${repo_part}' not found" >&2
                return 1
            elif [ "$repo_count" -eq 1 ]; then
                resolved_repo_path="$matching_repos"
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
            if [ -d "${ghq_root}/${repo_part}" ]; then
                resolved_repo_path="$repo_part"
            else
                echo "Error: Repository '${repo_part}' not found" >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Invalid repository format '${repo_part}'" >&2
            return 1
            ;;
    esac

    # Construct final path
    local final_path="${ghq_root}/${resolved_repo_path}"
    if [ -n "$subdir_part" ]; then
        final_path="${final_path}/${subdir_part}"
    fi

    # Change to the final path
    if [ -d "$final_path" ]; then
        cd "$final_path" || return 1
        return 0
    else
        echo "Error: Directory '${final_path}' not found" >&2
        return 1
    fi
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

# Helper function to get completion candidates with subdirectories
_ghq_cd_get_all_candidates() {
    local cur="$1"
    local ghq_root
    ghq_root=$(ghq root 2>/dev/null)
    if [ -z "$ghq_root" ]; then
        return 1
    fi

    local candidates=()
    local repos
    repos=$(ghq list 2>/dev/null)

    if [ -z "$repos" ]; then
        return 0
    fi

    # If no input yet, just show repository candidates
    if [ -z "$cur" ]; then
        _ghq_cd_get_candidates
        return 0
    fi

    # Try to match and expand based on current input
    while IFS= read -r repo; do
        local repo_name
        local account_repo
        repo_name=$(basename "$repo")
        account_repo="${repo#*/}"

        # Check if current input matches this repository
        local matched_repo=""
        local input_prefix=""

        if [[ "$cur" == "$repo"/* ]] || [[ "$cur" == "$repo" ]]; then
            matched_repo="$repo"
            input_prefix="$repo"
        elif [[ "$cur" == "$account_repo"/* ]] || [[ "$cur" == "$account_repo" ]]; then
            matched_repo="$repo"
            input_prefix="$account_repo"
        elif [[ "$cur" == "$repo_name"/* ]] || [[ "$cur" == "$repo_name" ]]; then
            # Only match by repo name if it's unique
            local count
            count=$(echo "$repos" | grep -c "/${repo_name}$")
            if [ "$count" -eq 1 ]; then
                matched_repo="$repo"
                input_prefix="$repo_name"
            fi
        fi

        # If we found a matching repository, generate subdirectory candidates
        if [ -n "$matched_repo" ]; then
            local repo_path="${ghq_root}/${matched_repo}"
            if [ -d "$repo_path" ]; then
                # Extract the subdirectory part from current input
                local subdir_input=""
                if [[ "$cur" == "$input_prefix"/* ]]; then
                    subdir_input="${cur#"${input_prefix}"/}"
                fi

                # Split subdir_input into confirmed path and partial input
                local confirmed_path=""
                local partial_input=""

                if [ -n "$subdir_input" ]; then
                    # Check if the input ends with a slash (meaning full path confirmed)
                    if [[ "$subdir_input" == */ ]]; then
                        confirmed_path="${subdir_input%/}"
                        partial_input=""
                    else
                        # Split at the last slash
                        if [[ "$subdir_input" == */* ]]; then
                            confirmed_path="${subdir_input%/*}"
                            partial_input="${subdir_input##*/}"
                        else
                            confirmed_path=""
                            partial_input="$subdir_input"
                        fi
                    fi
                fi

                # Determine the base directory to list
                local base_dir="$repo_path"
                if [ -n "$confirmed_path" ]; then
                    base_dir="${repo_path}/${confirmed_path}"
                fi

                # Add the repository itself as a candidate
                candidates+=("${input_prefix}")

                # List only direct subdirectories (1 depth)
                if [ -d "$base_dir" ]; then
                    while IFS= read -r subdir; do
                        if [ -n "$subdir" ] && [ "$subdir" != "." ]; then
                            # Filter by partial input if present
                            if [ -z "$partial_input" ] || [[ "$subdir" == "$partial_input"* ]]; then
                                if [ -n "$confirmed_path" ]; then
                                    candidates+=("${input_prefix}/${confirmed_path}/${subdir}")
                                else
                                    candidates+=("${input_prefix}/${subdir}")
                                fi
                            fi
                        fi
                    done < <(cd "$base_dir" 2>/dev/null && find . -maxdepth 1 -type d -not -name '.' -printf '%f\n' 2>/dev/null | sort)
                fi
            fi
        fi
    done <<< "$repos"

    # If no specific match, return basic candidates
    if [ ${#candidates[@]} -eq 0 ]; then
        _ghq_cd_get_candidates
    else
        printf '%s\n' "${candidates[@]}" | sort -u
    fi
}

# Zsh completion function
if [ -n "$ZSH_VERSION" ]; then
    _ghq_cd() {
        local -a candidates
        # shellcheck disable=SC2154
        local cur="${words[CURRENT]}"

        while IFS= read -r line; do
            candidates+=("$line")
        done < <(_ghq_cd_get_all_candidates "$cur")

        _describe 'repository' candidates
    }
    compdef _ghq_cd ghq-cd
fi

# Bash completion function
if [ -n "$BASH_VERSION" ]; then
    _ghq_cd_bash() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local candidates

        candidates=$(_ghq_cd_get_all_candidates "$cur")
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

    # Remove trailing slash from target_path if present
    target_path="${target_path%/}"

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

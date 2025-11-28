# ghq-utils

`ghq-utils` is a utility designed to simplify the use of the `ghq` command.

## Installation

Setting up `ghq-utils` is straightforward. You only need to source `ghq-utils.sh` from your shell.

```shell
git clone git@github.com:garaemon/ghq-utils
source ghq-utils/ghq-utils.sh
```

We recommend sourcing `ghq-utils.sh` in your `.bashrc` or `.zshrc` file for persistent access:

```shell
if [ -e /path/to/ghq-utils/ghq-utils.sh ]; then
  source /path/to/ghq-utils/ghq-utils.sh
fi
```

## `ghq-cd`

### Overview

`ghq-cd` is a utility that allows you to quickly navigate to the local directory of a repository
managed by `ghq`. This command is inspired by the [`roscd`](http://wiki.ros.org/rosbash#roscd)
command from ROS, which enables rapid navigation between ROS packages.

Instead of typing long paths like `cd ~/ghq/github.com/account/repository`, you can simply use
`ghq-cd repository` to jump directly to the repository directory.

### Quick Start

The most common usage is navigating by repository name:

```shell
# Navigate to a repository by name
ghq-cd ghq-utils

# Navigate to GHQ_ROOT
ghq-cd
```

### Detailed Usage

#### Navigate by Repository Name

```shell
ghq-cd <REPOSITORY-NAME>[/SUBDIRECTORY]
```

Changes the directory to the repository with the given name. This works only when there is exactly
one repository with this name under your `GHQ_ROOT`. You can also specify a subdirectory path to
navigate directly to a specific directory within the repository.

**Examples:**
```shell
ghq-cd ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils

ghq-cd ghq-utils/.github/workflows
# Changes to: ~/ghq/github.com/garaemon/ghq-utils/.github/workflows
```

**Note:** If multiple repositories share the same name (e.g., `user1/config` and `user2/config`),
the command will fail with an error. In this case, use the more specific forms below.

#### Navigate by Account and Repository

```shell
ghq-cd <ACCOUNT-NAME>/<REPOSITORY-NAME>[/SUBDIRECTORY]
```

Changes the directory to the specified repository under the given account. This is useful when
multiple repositories share the same name but belong to different accounts. You can also append a
subdirectory path.

**Examples:**
```shell
ghq-cd garaemon/ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils

ghq-cd garaemon/ghq-utils/src
# Changes to: ~/ghq/github.com/garaemon/ghq-utils/src
```

#### Navigate by Full Path

```shell
ghq-cd <HOSTNAME>/<ACCOUNT-NAME>/<REPOSITORY-NAME>[/SUBDIRECTORY]
```

Provides the most specific path, changing the directory to the repository located under the
specified hostname and account. This is useful when you have repositories with the same
account/repository name on different hosts. Subdirectory paths are also supported.

**Examples:**
```shell
ghq-cd github.com/garaemon/ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils

ghq-cd github.com/garaemon/ghq-utils/.github
# Changes to: ~/ghq/github.com/garaemon/ghq-utils/.github
```

#### Navigate to GHQ_ROOT

```shell
ghq-cd
```

When run without any arguments, `ghq-cd` changes the current directory to your `GHQ_ROOT`
(typically `~/ghq`).

### Tab Completion

`ghq-cd` supports intelligent tab completion for both repository paths and subdirectories. The
completion system provides:

- Repository name completion (all three formats: name, account/name, hostname/account/name)
- Subdirectory completion showing one level at a time for better usability
- Partial input matching (e.g., typing `ghq-utils/ro` and pressing Tab will complete to
  `ghq-utils/roles` if that directory exists)

**Examples:**
```shell
# Complete repository names
ghq-cd ghq[Tab]
# Shows: ghq-utils

# Complete subdirectories (one level at a time)
ghq-cd ghq-utils/[Tab]
# Shows: .github, src, docs, etc.

# Partial matching for subdirectories
ghq-cd ghq-utils/.gi[Tab]
# Completes to: ghq-utils/.github

# Continue to deeper levels
ghq-cd ghq-utils/.github/[Tab]
# Shows: workflows
```

### Common Use Cases

**Switching between projects quickly:**
```shell
# Working on project A
ghq-cd project-a
# ... do some work ...

# Switch to project B
ghq-cd project-b
# ... do some work ...

# Go back to GHQ_ROOT to see all repositories
ghq-cd
ls
```

**Working with forked repositories:**
```shell
# Navigate to your fork
ghq-cd yourname/some-project

# Navigate to the upstream repository
ghq-cd upstream/some-project
```

## `ghq-pull`

### Overview

`ghq-pull` automates the process of executing `git pull` across one or more specified repositories
without requiring manual directory navigation. This command saves you from repeatedly changing
directories and running `git pull` manually.

Instead of running `cd ~/ghq/github.com/account/repository && git pull`, you can simply execute
`ghq-pull repository` from anywhere to update the repository.

### Quick Start

The most common usage patterns:

```shell
# Pull the current repository (when inside a GHQ-managed repository)
ghq-pull

# Pull a specific repository by name
ghq-pull ghq-utils

# Pull all repositories
ghq-pull --all
```

### Detailed Usage

#### Pull Current Repository

```shell
ghq-pull
```

When executed from within a repository that is part of the `GHQ_ROOT` structure, `ghq-pull`
automatically performs a `git pull` operation for the current repository.

**Example:**
```shell
cd ~/ghq/github.com/garaemon/ghq-utils
ghq-pull
# Executes: git pull
# Output: Already up to date.
```

#### Pull a Specific Repository

```shell
ghq-pull <REPOSITORY-NAME>
ghq-pull <ACCOUNT-NAME>/<REPOSITORY-NAME>
ghq-pull <HOSTNAME>/<ACCOUNT-NAME>/<REPOSITORY-NAME>
```

Pulls a specific repository by name. If a unique repository matching `<REPOSITORY-NAME>` exists
under your `GHQ_ROOT`, `ghq-pull` will execute `git pull` within its directory. To resolve ambiguity
when multiple repositories share the same name, you can specify the `<ACCOUNT-NAME>` and optionally
the `<HOSTNAME>`.

**Examples:**
```shell
# Pull by repository name
ghq-pull ghq-utils
# Executes: git pull in ~/ghq/github.com/garaemon/ghq-utils

# Pull by account and repository
ghq-pull garaemon/ghq-utils
# Executes: git pull in ~/ghq/github.com/garaemon/ghq-utils

# Pull by full path
ghq-pull github.com/garaemon/ghq-utils
# Executes: git pull in ~/ghq/github.com/garaemon/ghq-utils
```

#### Pull All Repositories in an Account

```shell
ghq-pull <ACCOUNT-NAME>
ghq-pull <HOSTNAME>/<ACCOUNT-NAME>
```

Pulls all repositories associated with a given account. If a unique account matching
`<ACCOUNT-NAME>` exists under your `GHQ_ROOT`, `ghq-pull` will run `git pull` in all repositories
belonging to that account. To resolve ambiguity when multiple accounts share the same name, you can
specify the `<HOSTNAME>`.

**Examples:**
```shell
# Pull all repositories from an account
ghq-pull garaemon
# Executes: git pull in all repositories under */garaemon/*

# Pull all repositories from an account on a specific host
ghq-pull github.com/garaemon
# Executes: git pull in all repositories under github.com/garaemon/*
```

**Output example:**
```
Pulling github.com/garaemon/ghq-utils...
Already up to date.

Pulling github.com/garaemon/dotfiles...
Updating abc1234..def5678
Fast-forward
 .vimrc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

#### Pull All Repositories on a Host

```shell
ghq-pull <HOSTNAME>
```

Pulls all repositories managed under the specified `<HOSTNAME>`. `ghq-pull` will execute `git pull`
in every repository found within that host's directory structure.

**Example:**
```shell
ghq-pull github.com
# Executes: git pull in all repositories under github.com/*/*
```

#### Pull All Repositories

```shell
ghq-pull --all
```

Pulls all repositories located under the `GHQ_ROOT` directory. This command initiates `git pull` in
every managed repository.

**Example:**
```shell
ghq-pull --all
# Executes: git pull in all repositories under GHQ_ROOT
```

**Note:** This operation may take a significant amount of time if you have many repositories.

### Tab Completion

`ghq-pull` supports tab completion for repository paths, accounts, and hostnames, making it easy to
specify which repositories to pull without typing full names.

### Common Use Cases

**Daily repository updates:**
```shell
# Update all your personal projects
ghq-pull yourname

# Update all repositories from GitHub
ghq-pull github.com

# Update everything
ghq-pull --all
```

**Quick updates before starting work:**
```shell
# Navigate to a project and update it
ghq-cd some-project
ghq-pull
```

**Batch updates for a specific organization:**
```shell
# Update all repositories from a specific organization
ghq-pull github.com/organization-name
```

## `ghq-info`

### Overview

`ghq-info` displays information about repositories managed by `ghq`, including their account, name,
current branch, and full path. This is useful for quickly checking the status of repositories or
using the output in other scripts.

### Quick Start

```shell
# Show info for all repositories
ghq-info

# Show info for specific repository
ghq-info ghq-utils
```

### Detailed Usage

#### Show Info for All Repositories

```shell
ghq-info
```

When run without arguments, `ghq-info` displays details for all repositories managed by `ghq`.

**Example:**
```shell
ghq-info
# Output:
# garaemon/ghq-utils  main    /home/user/ghq/github.com/garaemon/ghq-utils
# garaemon/dotfiles   master  /home/user/ghq/github.com/garaemon/dotfiles
# ...
```

#### Show Info for Specific Repository

```shell
ghq-info <REPOSITORY-NAME>
ghq-info <ACCOUNT-NAME>/<REPOSITORY-NAME>
ghq-info <HOSTNAME>/<ACCOUNT-NAME>/<REPOSITORY-NAME>
```

Displays information for the specified repository. If multiple repositories match the name, all
matches are listed.

**Examples:**
```shell
ghq-info ghq-utils
# Output: garaemon/ghq-utils  main  /home/user/ghq/github.com/garaemon/ghq-utils

ghq-info garaemon/ghq-utils
# Output: garaemon/ghq-utils  main  /home/user/ghq/github.com/garaemon/ghq-utils
```

#### Show Info for All Repositories in an Account

```shell
ghq-info <ACCOUNT-NAME>
```

Lists information for all repositories belonging to the specified account.

**Example:**
```shell
ghq-info garaemon
# Output:
# garaemon/ghq-utils  main    /home/user/ghq/github.com/garaemon/ghq-utils
# garaemon/dotfiles   master  /home/user/ghq/github.com/garaemon/dotfiles
```

### Output Format

The output format is:
```
account_name/repository_name branch_name full_path
```

- **account_name/repository_name**: The repository identifier.
- **branch_name**: The current checked-out branch (or "unknown" / "not-a-git-repo").
- **full_path**: The absolute path to the repository.

## Development

### Running Tests

This project uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for testing.

**Prerequisites:**
- `shellcheck` for linting
- `bats` for running tests

**Install dependencies:**
```shell
# On Ubuntu/Debian
sudo apt-get install shellcheck bats

# On macOS
brew install shellcheck bats-core
```

**Run linter:**
```shell
shellcheck ghq-utils.sh
```

**Run tests:**
```shell
bats test_ghq_utils.bats
```

**Run all checks (linter + tests):**
```shell
shellcheck ghq-utils.sh && bats test_ghq_utils.bats
```

Tests are also automatically run via GitHub Actions CI on every pull request.

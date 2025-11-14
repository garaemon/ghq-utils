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
ghq-cd <REPOSITORY-NAME>
```

Changes the directory to the repository with the given name. This works only when there is exactly
one repository with this name under your `GHQ_ROOT`.

**Example:**
```shell
ghq-cd ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils
```

**Note:** If multiple repositories share the same name (e.g., `user1/config` and `user2/config`),
the command will fail with an error. In this case, use the more specific forms below.

#### Navigate by Account and Repository

```shell
ghq-cd <ACCOUNT-NAME>/<REPOSITORY-NAME>
```

Changes the directory to the specified repository under the given account. This is useful when
multiple repositories share the same name but belong to different accounts.

**Example:**
```shell
ghq-cd garaemon/ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils
```

#### Navigate by Full Path

```shell
ghq-cd <HOSTNAME>/<ACCOUNT-NAME>/<REPOSITORY-NAME>
```

Provides the most specific path, changing the directory to the repository located under the
specified hostname and account. This is useful when you have repositories with the same
account/repository name on different hosts.

**Example:**
```shell
ghq-cd github.com/garaemon/ghq-utils
# Changes to: ~/ghq/github.com/garaemon/ghq-utils
```

#### Navigate to GHQ_ROOT

```shell
ghq-cd
```

When run without any arguments, `ghq-cd` changes the current directory to your `GHQ_ROOT`
(typically `~/ghq`).

### Tab Completion

`ghq-cd` supports tab completion for repository paths, making it easy to discover and navigate to
repositories without typing full names.

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

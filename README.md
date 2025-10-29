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

`ghq-cd` is a utility that allows you to quickly navigate to the local directory of a repository managed by `ghq`.

### Synopsis

```shell
ghq-cd [hostname/][account_name/]repository_name
ghq-cd
```

### Usage and Behavior

`ghq-cd` provides several ways to change your current directory:

*   **`ghq-cd <REPOSITORY-NAME>`**
    If there is exactly one repository with the given `<REPOSITORY-NAME>` under your `GHQ_ROOT` directory, `ghq-cd` will change the directory to that repository. If multiple repositories share the same name or if no repository is found, the command will fail.

*   **`ghq-cd <ACCOUNT-NAME>/<REPOSITORY-NAME>`**
    This command will change the directory to the specified repository under the given account. If the repository does not exist within `GHQ_ROOT`, the command will fail.

*   **`ghq-cd <HOSTNAME>/<ACCOUNT-NAME>/<REPOSITORY-NAME>`**
    This command provides the most specific path, changing the directory to the repository located under the specified hostname and account. If the repository does not exist within `GHQ_ROOT`, the command will fail.

*   **`ghq-cd` (without arguments)**
    When run without any arguments, `ghq-cd` will change the current directory to your `GHQ_ROOT`.

### Example

First, fetch a repository using `ghq`:

```shell
ghq get garaemon/ghq-utils
```

Then, navigate to its directory with `ghq-cd`:

```shell
ghq-cd ghq-utils
ghq-cd garaemon/ghq-utils
ghq-cd github.com/garaemon/ghq-utils
```

## `ghq-pull`

`ghq-pull` automates the process of executing `git pull` across one or more specified repositories without requiring manual directory navigation.

### Synopsis

```shell
ghq-pull
ghq-pull [hostname/][account_name/]repository_name
ghq-pull [hostname/]account_name
ghq-pull hostname
ghq-pull --all
```

### Usage

`ghq-pull` supports several methods for initiating `git pull` operations:

*   **`ghq-pull [<HOSTNAME>/][<ACCOUNT-NAME>/]<REPOSITORY-NAME>`**
    Pulls a specific repository. If a unique repository matching `<REPOSITORY-NAME>` exists under your `GHQ_ROOT`, `ghq-pull` will execute `git pull` within its directory. To resolve ambiguity when multiple repositories share the same name, you can specify the `<ACCOUNT-NAME>` and optionally the `<HOSTNAME>`.

*   **`ghq-pull [<HOSTNAME>/]<ACCOUNT-NAME>`**
    Pulls all repositories associated with a given account. If a unique account matching `<ACCOUNT-NAME>` exists under your `GHQ_ROOT`, `ghq-pull` will run `git pull` in all repositories belonging to that account. To resolve ambiguity when multiple accounts share the same name, you can specify the `<HOSTNAME>`.

*   **`ghq-pull <HOSTNAME>`**
    Pulls all repositories managed under the specified `<HOSTNAME>`. `ghq-pull` will execute `git pull` in every repository found within that host's directory structure.

*   **`ghq-pull --all`**
    Pulls all repositories located under the `GHQ_ROOT` directory. This command initiates `git pull` in every managed repository.

*   **`ghq-pull` (no arguments)**
    If executed from within a repository that is part of the `GHQ_ROOT` structure, `ghq-pull` will automatically perform a `git pull` operation for the current repository.

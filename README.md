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

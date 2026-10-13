# ctt

**C**laudeCode **T**ask management on **T**erminal workspaces

A CLI tool for managing development tasks using git worktrees. Each task runs in an isolated worktree with Claude Code in its own [herdr](https://herdr.dev) workspace (default) or tmux window.

Written in [MoonBit](https://www.moonbitlang.com/) and compiled to a native binary.

## Requirements

- [fzf](https://github.com/junegunn/fzf)
- git
- [gh](https://cli.github.com/) (GitHub CLI)
- herdr mode (default): [herdr](https://herdr.dev) and the `claude` CLI
- tmux mode: tmux, Neovim + [claudecode.nvim](https://github.com/anthropics/claudecode.nvim)

## Installation

### Homebrew (recommended)

```bash
brew install foresta/tap/ctt
```

This installs a pre-built native binary and seeds `~/.config/ctt/.worktree-link-ignore` on first install. `config.toml` is optional; create it only to change the defaults below.

### Build from source

Requires [MoonBit](https://www.moonbitlang.com/download/).

```bash
git clone https://github.com/foresta/ctt.git
cd ctt
make install
```

This builds the native binary and installs `ctt` to `~/.local/bin/` and config files to `~/.config/ctt/`.
Ensure `~/.local/bin` is in your `PATH`.

## Usage

```bash
ctt <command>
```

### Commands

- `ctt new` - Create a worktree and open it in a workspace with Claude Code
- `ctt ls` - List active tasks
- `ctt open` - Open (or focus) the workspace of an existing task
- `ctt status` - Show task status (use `--all` for all tasks)
- `ctt done` - Close the workspace, remove the worktree and optionally delete the branch
- `ctt version` (or `ctt --version`) - Print version

Without arguments, `new`, `open`, `status` and `done` ask for what they need with fzf.

### Non-interactive usage

Every prompt can be answered up front, which makes `ctt` usable from scripts and coding agents. Only the prompts you leave out are shown.

```bash
ctt new --repo ctt --branch main --no-focus            # check out an existing branch
ctt new --repo ctt --branch feat-x --base main         # create feat-x from main
ctt open ctt__feat-x --no-focus
ctt status ctt__feat-x
ctt done ctt__feat-x --yes --delete-branch
```

| Option | Applies to | Meaning |
|--------|-----------|---------|
| `--repo <name\|path>` | `new` | Repository under the workspace, by directory name or absolute path. Ambiguous names must be given as a path |
| `--branch <branch>` | `new` | Branch to check out. With `--base`, the branch is created from `--base` instead |
| `--no-focus` | `new`, `open` | Create the workspace without switching to it |
| `--yes` | `done` | Skip the removal confirmation. The branch is kept unless `--delete-branch` is also given |
| `--delete-branch` | `done` | Delete the local branch with `git branch -d`; an unmerged branch is left in place with a warning |

`new` with `--branch` reuses an existing worktree without asking (after checking it is on that branch), so it is safe to run repeatedly. `new` and `open` print `Worktree: <path>` as their last line. The exit status is 1 on any error, unknown command or option, or cancelled prompt. In tmux mode, `--no-focus` requires running inside tmux.

## Configuration

### `config.toml`

`~/.config/ctt/config.toml` selects the terminal backend. All keys are optional; a missing file means the defaults below.

```toml
multiplexer = "herdr"   # "herdr" (default) or "tmux"

[herdr]
agent_command = "claude"                           # left pane, new worktree
agent_resume_command = "claude --continue || claude"  # left pane, existing worktree
```

| Key | Default | Description |
|-----|---------|-------------|
| `multiplexer` | `"herdr"` | Backend used by `new` / `open` / `done` |
| `herdr.agent_command` | `"claude"` | Shell line run in the agent pane when `new` creates a worktree |
| `herdr.agent_resume_command` | `"<agent_command> --continue \|\| <agent_command>"` | Shell line run instead when the worktree already exists (`open`, or `new` on an existing worktree). The default resumes the last session and falls back to a fresh one when the resume exits non-zero, which is what `claude --continue` does when there is nothing to resume. Any other non-zero exit of the resumed session also starts a fresh one. The lines are typed into the pane's shell, so the default assumes a POSIX-style `\|\|`; set it explicitly for other shells |

**herdr mode** creates one workspace labelled `<repo>__<branch>` per task with a single tab: the left pane runs `agent_command` (or `agent_resume_command` for an existing worktree) and the right pane is a shell in the worktree. Running `new` or `open` on a task whose workspace is already open only focuses it. `done` closes the workspace before removing the worktree.

**tmux mode** keeps the original behaviour: a tmux window named `<repo>__<branch>` running `nvim . -c ClaudeCode` (`ClaudeCode --continue` on `open`), closed by `done`. If the window already exists it is selected instead of duplicated.

### `.worktree-link-ignore`

`~/.config/ctt/.worktree-link-ignore` controls which git-ignored files are **not** symlinked into worktrees. The syntax follows `.gitignore`:

```gitignore
# Comments start with #
.DS_Store
*.log
build/
**/node_modules
!important.log
```

| Pattern | Description |
|---------|-------------|
| `*` | Matches any characters except `/` |
| `**` | Matches any characters including `/` (crosses directory boundaries) |
| `?` | Matches a single character except `/` |
| `/pattern` | Anchored to root — matches only at the top level |
| `pattern/` | Matches directories (trailing slash is stripped) |
| `!pattern` | Negation — re-includes a previously excluded file |
| `# text` | Comment line (ignored) |

Patterns without `/` match against any path component (e.g., `*.log` matches `build/debug.log`). Patterns containing `/` are matched against the full relative path.

## Development

```bash
cd src
moon build --target native        # Debug build
moon build --target native --release  # Release build
moon run --target native cmd/main -- ls  # Run directly
moon test --target native         # Run tests
```

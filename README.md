# ctt

**C**laudeCode **T**ask management on **T**mux

A CLI tool for managing development tasks using git worktrees. Each task runs in an isolated worktree with Neovim + ClaudeCode in a dedicated tmux window.

Written in [MoonBit](https://www.moonbitlang.com/) and compiled to a native binary.

## Requirements

- [MoonBit](https://www.moonbitlang.com/download/) (for building)
- [fzf](https://github.com/junegunn/fzf)
- git
- [gh](https://cli.github.com/) (GitHub CLI)
- tmux
- Neovim + [claudecode.nvim](https://github.com/anthropics/claudecode.nvim)

## Installation

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

- `ctt new` - Create a worktree and launch ClaudeCode
- `ctt ls` - List active tasks
- `ctt open` - Open an existing task in the editor
- `ctt status` - Show task status (use `--all` for all tasks)
- `ctt done` - Complete a task and remove its worktree

## Configuration

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

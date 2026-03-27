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

## Development

```bash
cd src
moon build --target native        # Debug build
moon build --target native --release  # Release build
moon run --target native cmd/main -- ls  # Run directly
moon test --target native         # Run tests
```

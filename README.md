# ctt

**C**laudeCode **T**ask management on **T**mux

A CLI tool for managing development tasks using git worktrees. Each task runs in an isolated worktree with Neovim + ClaudeCode in a dedicated tmux window.

## Requirements

- bash
- [fzf](https://github.com/junegunn/fzf)
- git
- [gh](https://cli.github.com/) (GitHub CLI)
- tmux
- Neovim + [claudecode.nvim](https://github.com/anthropics/claudecode.nvim)

## Installation

```bash
git clone https://github.com/your-user/ctt.git
cd ctt
make install
```

This installs `ctt` to `~/.local/bin/` and config files to `~/.config/ctt/`.
Ensure `~/.local/bin` is in your `PATH`.

## Usage

```bash
ctt <command>
```

Run `ctt` without arguments to see available commands.

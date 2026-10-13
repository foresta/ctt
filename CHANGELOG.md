# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- herdr backend (default): `ctt new` / `ctt open` create one herdr workspace per task with Claude Code in the left pane and a shell in the right pane; `ctt done` closes it
- `~/.config/ctt/config.toml` with `multiplexer` (`"herdr"` | `"tmux"`) and `herdr.agent_command`

### Changed
- The default backend is now herdr; set `multiplexer = "tmux"` to keep the previous tmux + nvim behaviour
- `ctt new` / `ctt open` now report workspace launch failures instead of ignoring them
- tmux mode: `ctt open` selects the existing window instead of opening a duplicate
- `ctt done` prints `Closed workspace: <name>` instead of `Closed tmux window: <name>`

## [0.1.0] - 2026-04-24

### Added
- Initial release
- `ctt new` — create a worktree and launch ClaudeCode in a dedicated tmux window
- `ctt ls` — list active worktrees
- `ctt open` — open a worktree in the editor
- `ctt status` — show worktree status
- `ctt done` — complete and remove a worktree
- `ctt --version` / `ctt version` — print version
- Homebrew tap distribution (`brew install foresta/tap/ctt`)
- `.worktree-link-ignore` glob pattern support for controlling symlinked files

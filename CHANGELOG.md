# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `new --context <text>` / `--context-file <path|->` / `--context-url <url>` (and an optional prompt in the interactive flow): the text is filled into `[agent] prompt_template`, saved under `~/.config/ctt/tasks/`, and handed to the agent as its first prompt through the `{prompt}` placeholder in `herdr.agent_command` / `agent_resume_command`
- Non-interactive arguments: `new --repo --branch [--base]`, `open <name>`, `done <name> --yes [--delete-branch]`, `status <name>`; omitted arguments are still asked interactively
- `--no-focus` for `new` / `open` to create the workspace without switching to it
- Exit status 1 on errors, unknown commands or options, and cancelled prompts; `new` / `open` print `Worktree: <path>`
- herdr backend (default): `ctt new` / `ctt open` create one herdr workspace per task with Claude Code in the left pane and a shell in the right pane; `ctt done` closes it
- `~/.config/ctt/config.toml` with `multiplexer` (`"herdr"` | `"tmux"`), `herdr.agent_command` and `herdr.agent_resume_command`
- Reopening a worktree whose Claude session was never written falls back to a fresh session: the resume command defaults to `<agent_command> --continue || <agent_command>`

### Fixed
- `done` never deleted the branch: it resolved the git directory from the already removed worktree

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

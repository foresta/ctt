# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-10-19

The default terminal backend is now [herdr](https://herdr.dev). tmux users keep the previous behaviour with `multiplexer = "tmux"` in `~/.config/ctt/config.toml`.

### Added
- herdr backend (default): `ctt new` / `ctt open` create one herdr workspace per task with Claude Code in the left pane and a shell in the right pane; `ctt done` closes it
- `~/.config/ctt/config.toml` with `multiplexer` (`"herdr"` | `"tmux"`), `[agent] prompt_template`, `herdr.agent_command` and `herdr.agent_resume_command`
- Non-interactive arguments: `new --repo --branch [--base]`, `open <name>`, `done <name> --yes [--delete-branch]`, `status <name>`; omitted arguments are still asked interactively
- `new --context <text>` / `--context-file <path|->` / `--context-url <url>` (and an optional prompt in the interactive flow): the text is filled into `[agent] prompt_template`, saved under `~/.config/ctt/tasks/`, and handed to the agent as its first prompt through the `{prompt}` placeholder in `herdr.agent_command` / `agent_resume_command`
- `--no-focus` for `new` / `open` to create the workspace without switching to it
- Exit status 1 on errors, unknown commands or options, and cancelled prompts; `new` / `open` print `Worktree: <path>`
- Reopening a worktree whose Claude session was never written falls back to a fresh session: the resume command defaults to `<agent_command> --continue || <agent_command>`
- `done` can be run from inside the task's own workspace: cleanup happens first and the workspace closes shortly after `ctt` has exited

### Changed
- The default backend is now herdr; set `multiplexer = "tmux"` to keep the previous tmux + nvim behaviour
- `ctt new` / `ctt open` now report workspace launch failures instead of ignoring them
- tmux mode: `ctt open` selects the existing window instead of opening a duplicate
- `ctt done` prints `Closed workspace: <name>` instead of `Closed tmux window: <name>`
- Builds and releases target Apple Silicon only; MoonBit ships no Intel macOS toolchain

### Fixed
- `done` never deleted the branch: it resolved the git directory from the already removed worktree
- `done` run from inside the task's workspace closed that workspace first, which killed `ctt` itself and left the worktree and branch behind

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

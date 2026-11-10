///|
/// What `WorkspaceManager::open` did.
pub(all) enum OpenOutcome {
  /// A workspace was created and the agent command was started.
  Created
  /// The workspace already existed; nothing was started (it may have been focused).
  Reused
} derive(Eq, Debug)

///|
pub extend OpenOutcome with Eq::{ equal, not_equal }

///|
pub extend OpenOutcome with @debug.Debug::{ to_repr }

///|
/// What `WorkspaceManager::close` / `close_later` did.
pub(all) enum CloseOutcome {
  /// The workspace was closed (or scheduled to close).
  Closed
  /// No open workspace exists for the task.
  NotFound
  /// The backend could not look, for example tmux mode outside tmux; the
  /// reason is for the user.
  Unavailable(String)
} derive(Eq, Debug)

///|
pub extend CloseOutcome with Eq::{ equal, not_equal }

///|
pub extend CloseOutcome with @debug.Debug::{ to_repr }

///|
/// What `WorkspaceManager::set_title` did.
pub(all) enum TitleOutcome {
  /// The open workspace now shows the title.
  Applied
  /// No open workspace exists for the task.
  NotFound
  /// The backend does not show titles; the reason is for the user.
  Unavailable(String)
} derive(Eq, Debug)

///|
pub extend TitleOutcome with Eq::{ equal, not_equal }

///|
pub extend TitleOutcome with @debug.Debug::{ to_repr }

///|
/// Port for the terminal workspace a task runs in (a tmux window, a herdr workspace, ...).
/// Workspaces are identified by the task name `<repo_name>__<branch>`.
pub(open) trait WorkspaceManager {
  /// Open the workspace for a task, or reuse it when it already exists.
  /// With `focus`, the workspace is brought to the front. `prompt_file` is the
  /// saved task prompt handed to the agent, when there is one; `title` is
  /// shown alongside the task name where the backend can.
  async open(Self, repo_name~ : String, branch~ : String, workdir~ : String, continue_session~ : Bool, focus~ : Bool, prompt_file~ : String?, title~ : String?) -> Result[OpenOutcome, String]
  /// Show `title` on the open workspace named `name`.
  async set_title(Self, name~ : String, title~ : String) -> Result[TitleOutcome, String]
  /// Whether the agent launched by this backend can receive the task prompt.
  supports_prompt(Self) -> Bool
  /// Whether the calling process runs inside the workspace named `name`.
  async is_current(Self, name~ : String) -> Result[Bool, String]
  /// Close the workspace named `name`.
  async close(Self, name~ : String) -> Result[CloseOutcome, String]
  /// Close the workspace named `name` shortly after the calling process has
  /// exited, for use when the caller itself lives in that workspace.
  async close_later(Self, name~ : String) -> Result[CloseOutcome, String]
}

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
/// Port for the terminal workspace a task runs in (a tmux window, a herdr workspace, ...).
/// Workspaces are identified by the task name `<repo_name>__<branch>`.
pub(open) trait WorkspaceManager {
  /// Open the workspace for a task, or reuse it when it already exists.
  /// With `focus`, the workspace is brought to the front. `prompt_file` is the
  /// saved task prompt handed to the agent, when there is one.
  async open(Self, repo_name~ : String, branch~ : String, workdir~ : String, continue_session~ : Bool, focus~ : Bool, prompt_file~ : String?) -> Result[OpenOutcome, String]
  /// Whether the agent launched by this backend can receive the task prompt.
  supports_prompt(Self) -> Bool
  /// Close the workspace named `name`. Ok(true) when closed, Ok(false) when none existed.
  async close(Self, name~ : String) -> Result[Bool, String]
}

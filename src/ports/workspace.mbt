///|
/// Port for the terminal workspace a task runs in (a tmux window, a herdr workspace, ...).
/// Workspaces are identified by the task name `<repo_name>__<branch>`.
pub(open) trait WorkspaceManager {
  /// Open the workspace for a task, or reuse it when it already exists.
  /// With `focus`, the workspace is brought to the front.
  async open(Self, repo_name~ : String, branch~ : String, workdir~ : String, continue_session~ : Bool, focus~ : Bool) -> Result[Unit, String]
  /// Close the workspace named `name`. Ok(true) when closed, Ok(false) when none existed.
  async close(Self, name~ : String) -> Result[Bool, String]
}

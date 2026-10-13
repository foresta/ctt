///|
/// Port for the terminal workspace a task runs in (a tmux window, a herdr workspace, ...).
/// Workspaces are identified by the task name `<repo_name>__<branch>`.
pub(open) trait WorkspaceManager {
  /// Open the workspace for a task, or focus it when it already exists.
  async fn open(
    Self,
    repo_name~ : String,
    branch~ : String,
    workdir~ : String,
    continue_session~ : Bool,
  ) -> Result[Unit, String]
  /// Close the workspace named `name`. Ok(true) when closed, Ok(false) when none existed.
  async fn close(Self, name~ : String) -> Result[Bool, String]
}

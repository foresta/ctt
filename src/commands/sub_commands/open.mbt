///|
/// Opens an existing worktree in its workspace via interactive selection.
pub(all) struct OpenCommand {
  workspace : &@ports.WorkspaceManager
  worktrees : &@ports.WorktreeRepository
}

///|
/// Returns a Select step for the user to pick a worktree, then opens its workspace.
impl @ports.Runnable for OpenCommand with run(self) {
  let worktree_list = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktree_list.is_empty() {
    return @ports.Lines(["No active worktrees."])
  }
  let names = worktree_list.map(fn(t) { t.name })
  let workspace = self.workspace
  @ports.Select(
    items=names,
    prompt="Select Worktree> ",
    on_select=async fn(name) {
      match worktree_list.iter().find_first(fn(t) { t.name == name }) {
        Some(wt) =>
          match workspace.open(
            repo_name=wt.repo_name,
            branch=wt.branch,
            workdir=wt.workdir,
            continue_session=true,
          ) {
            Ok(_) => @ports.Lines(["Opened: " + wt.name])
            Err(e) => @ports.Error(e)
          }
        None => @ports.Error("worktree not found: " + name)
      }
    },
  )
}

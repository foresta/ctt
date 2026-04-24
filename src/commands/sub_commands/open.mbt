///|
/// Opens an existing worktree in the editor via interactive selection.
pub(all) struct OpenCommand {
  editor : &@ports.EditorLauncher
  worktrees : &@ports.WorktreeRepository
}

///|
/// Returns a Select step for the user to pick a worktree, then opens the editor.
impl @ports.Runnable for OpenCommand with run(self) {
  let worktree_list = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktree_list.is_empty() {
    return @ports.Lines(["No active worktrees."])
  }
  let names = worktree_list.map(fn(t) { t.name })
  let editor = self.editor
  @ports.Select(
    items=names,
    prompt="Select Worktree> ",
    on_select=async fn(name) {
      match worktree_list.iter().find_first(fn(t) { t.name == name }) {
        Some(wt) => {
          let _ = editor.open(
            repo_name=wt.repo_name,
            workdir=wt.workdir,
            branch=wt.branch,
            continue_session=true,
          )
          @ports.Lines(["Opened: " + wt.name])
        }
        None => @ports.Error("worktree not found: " + name)
      }
    },
  )
}

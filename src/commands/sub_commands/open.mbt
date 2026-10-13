///|
/// Opens an existing worktree in its workspace, by name or via interactive selection.
pub(all) struct OpenCommand {
  workspace : &@ports.WorkspaceManager
  worktrees : &@ports.WorktreeRepository
  opts : OpenOptions
}

///|
impl @ports.Runnable for OpenCommand with run(self) {
  pick_worktree(self.worktrees, self.opts.name, "Select Worktree> ", async fn(wt) {
    self.open_worktree(wt)
  })
}

///|
async fn OpenCommand::open_worktree(
  self : OpenCommand,
  wt : @ports.Worktree
) -> @ports.CommandResult {
  match self.workspace.open(
    repo_name=wt.repo_name,
    branch=wt.branch,
    workdir=wt.workdir,
    continue_session=true,
    focus=self.opts.focus,
  ) {
    Ok(_) => @ports.Lines(["Opened: " + wt.name, "Worktree: " + wt.workdir])
    Err(e) => @ports.Error(e)
  }
}

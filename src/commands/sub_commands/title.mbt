///|
/// Gives a task a short title: saved by ctt and shown on its open workspace.
pub(all) struct TitleCommand {
  workspace : &@ports.WorkspaceManager
  worktrees : &@ports.WorktreeRepository
  worktree : @domain.WorktreeService
  opts : TitleOptions
}

///|
impl @ports.Runnable for TitleCommand with run(self) {
  pick_worktree(
    self.worktrees, Some(self.opts.name), "Select Worktree> ",
    async fn(wt) { self.apply(wt.name) },
  )
}

///|
async fn TitleCommand::apply(self : TitleCommand, name : String) -> @ports.CommandResult {
  let title = self.opts.title
  match self.worktree.save_title(name, title) {
    Ok(_) => ()
    Err(e) => return @ports.Error(e)
  }
  let lines = ["Title: " + title]
  match self.workspace.set_title(name~, title~) {
    Ok(Applied) => lines.push("Renamed workspace: " + name)
    Ok(NotFound) =>
      lines.push("No open workspace found for " + name + "; the title is shown when it is opened next.")
    Ok(Unavailable(reason)) => lines.push("Note: " + reason + ", so only the saved title changed.")
    Err(e) => lines.push("Warning: failed to rename workspace: " + e)
  }
  @ports.Lines(lines)
}

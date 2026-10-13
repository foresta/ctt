///|
/// Builds a Table with header and status rows for the given worktrees.
async fn build_status_table(
  vcs : &@ports.VCS,
  worktrees : Array[@ports.Worktree]
) -> @ports.CommandResult {
  let header = ["WORKTREE", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
  let rows : Array[Array[String]] = [header]
  for wt in worktrees {
    match vcs.get_worktree_status(name=wt.name, workdir=wt.workdir) {
      Ok(info) => rows.push(info.to_row())
      Err(e) => rows.push([wt.name, "error", e, "", "", ""])
    }
  }
  @ports.Table(rows)
}

///|
/// Shows git and PR status for worktrees: all of them, one by name, or one picked interactively.
pub(all) struct StatusCommand {
  vcs : &@ports.VCS
  worktrees : &@ports.WorktreeRepository
  opts : StatusOptions
}

///|
impl @ports.Runnable for StatusCommand with run(self) {
  if self.opts.all {
    let worktree_list = match self.worktrees.list() {
      Ok(t) => t
      Err(e) => return @ports.Error(e)
    }
    if worktree_list.is_empty() {
      return @ports.Lines(["No active worktrees."])
    }
    return build_status_table(self.vcs, worktree_list)
  }
  let vcs = self.vcs
  pick_worktree(self.worktrees, self.opts.name, "Select Worktree> ", async fn(wt) {
    build_status_table(vcs, [wt])
  })
}

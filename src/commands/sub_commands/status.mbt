///|
/// Builds a Table with header and status rows for the given worktrees.
async fn build_status_table(
  vcs : &@ports.VCS,
  worktree : @domain.WorktreeService,
  worktrees : Array[@ports.Worktree]
) -> @ports.CommandResult {
  let header = ["WORKTREE", "TITLE", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
  let rows : Array[Array[String]] = [header]
  for wt in worktrees {
    let title = worktree.existing_title(wt.name).unwrap_or("")
    let row = match vcs.get_worktree_status(name=wt.name, workdir=wt.workdir) {
      Ok(info) => info.to_row()
      Err(e) => [wt.name, "error", e, "", "", ""]
    }
    row.insert(1, title)
    rows.push(row)
  }
  @ports.Table(rows)
}

///|
/// Shows git and PR status for worktrees: all of them, one by name, or one picked interactively.
pub(all) struct StatusCommand {
  vcs : &@ports.VCS
  worktrees : &@ports.WorktreeRepository
  worktree : @domain.WorktreeService
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
    return build_status_table(self.vcs, self.worktree, worktree_list)
  }
  let vcs = self.vcs
  let worktree = self.worktree
  pick_worktree(self.worktrees, self.opts.name, "Select Worktree> ", async fn(wt) {
    build_status_table(vcs, worktree, [wt])
  })
}

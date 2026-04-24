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
/// Shows git and PR status for worktrees. `--all` shows all, otherwise prompts for selection.
pub(all) struct StatusCommand {
  vcs : &@ports.VCS
  worktrees : &@ports.WorktreeRepository
  params : Array[String]
}

///|
/// Returns a Table for --all, or a Select step then Table for a single worktree.
impl @ports.Runnable for StatusCommand with run(self) {
  let show_all = self.params.length() > 0 && self.params[0] == "--all"
  let worktree_list = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktree_list.is_empty() {
    return @ports.Lines(["No active worktrees."])
  }
  if show_all {
    return build_status_table(self.vcs, worktree_list)
  }
  let names = worktree_list.map(fn(t) { t.name })
  let vcs = self.vcs
  @ports.Select(
    items=names,
    prompt="Select Worktree> ",
    on_select=async fn(name) {
      match worktree_list.iter().find_first(fn(t) { t.name == name }) {
        Some(wt) => build_status_table(vcs, [wt])
        None => @ports.Error("worktree not found: " + name)
      }
    },
  )
}

///|
/// Lists all active worktree names, with their titles when any task has one.
pub(all) struct LsCommand {
  worktrees : &@ports.WorktreeRepository
  worktree : @domain.WorktreeService
}

///|
impl @ports.Runnable for LsCommand with run(self) {
  let worktrees = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktrees.is_empty() {
    return @ports.Lines(["No active worktrees."])
  }
  let rows = worktrees.map(fn(t) {
    [t.name, self.worktree.existing_title(t.name).unwrap_or("")]
  })
  // Plain names when nothing is titled, so existing scripts see no change.
  if rows.iter().all(fn(r) { r[1] == "" }) {
    @ports.Lines(rows.map(fn(r) { r[0] }))
  } else {
    @ports.Table(rows)
  }
}

///|
/// Lists all active worktree names.
pub(all) struct LsCommand {
  worktrees : &@ports.WorktreeRepository
}

///|
/// Returns worktree names as Lines, or an Error if listing fails.
impl @ports.Runnable for LsCommand with run(self) {
  let worktrees = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktrees.is_empty() {
    @ports.Lines(["No active worktrees."])
  } else {
    @ports.Lines(worktrees.map(fn(t) { t.name }))
  }
}

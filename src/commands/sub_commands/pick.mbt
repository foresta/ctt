///|
/// Resolve a worktree by name when one was given, otherwise let the user pick
/// one from the list. `k` receives the chosen worktree.
async fn pick_worktree(
  worktrees : &@ports.WorktreeRepository,
  name : String?,
  prompt : String,
  k : async (@ports.Worktree) -> @ports.CommandResult
) -> @ports.CommandResult {
  let worktree_list = match worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  let find = fn(name : String) -> @ports.Worktree? {
    worktree_list.iter().find_first(fn(t) { t.name == name })
  }
  match name {
    Some(name) =>
      match find(name) {
        Some(wt) => k(wt)
        None => @ports.Error("worktree not found: " + name)
      }
    None => {
      if worktree_list.is_empty() {
        return @ports.Lines(["No active worktrees."])
      }
      @ports.Select(
        items=worktree_list.map(fn(t) { t.name }),
        prompt=prompt,
        on_select=async fn(name) {
          match find(name) {
            Some(wt) => k(wt)
            None => @ports.Error("worktree not found: " + name)
          }
        },
      )
    }
  }
}

///|
/// A task representing a git worktree with its associated metadata.
pub(all) struct Task {
  name : String
  repo_name : String
  branch : String
  workdir : String
}

///|
/// Parse a task name into a repo name and branch name, split by "__".
pub fn parse_task_name(name : String) -> (String, String) {
  match name.find("__") {
    Some(idx) => (name[:idx].to_string(), name[idx + 2:].to_string())
    None => (name, "")
  }
}

///|
/// Return the worktrees directory path under the given workspace directory.
pub fn worktree_dir(workspace_dir : String) -> String {
  workspace_dir + "/worktrees"
}

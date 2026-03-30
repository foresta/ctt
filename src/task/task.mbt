///|
pub(all) struct Task {
  name : String
  repo_name : String
  branch : String
  workdir : String
}

///|
pub fn parse_task_name(name : String) -> (String, String) {
  match name.find("__") {
    Some(idx) => (name[:idx].to_string(), name[idx + 2:].to_string())
    None => (name, "")
  }
}

///|
pub fn worktree_dir(workspace_dir : String) -> String {
  workspace_dir + "/worktrees"
}

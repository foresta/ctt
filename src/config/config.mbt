///|
pub fn home_dir() -> String {
  match @sys.get_env_var("HOME") {
    Some(home) => home
    None => panic() // HOME must be set
  }
}

///|
pub fn workspace_dir() -> String {
  @path.Path(home_dir()).join(@path.Path("work")).to_string()
}

///|
pub fn worktree_dir() -> String {
  @path.Path(workspace_dir()).join(@path.Path("worktrees")).to_string()
}

///|
pub fn config_dir() -> String {
  @path.Path(home_dir()).join(@path.Path(".config/ctt")).to_string()
}

///|
/// Return the user's home directory from the HOME environment variable.
pub fn home_dir() -> String {
  match @sys.get_env_var("HOME") {
    Some(home) => home
    None => panic() // HOME must be set
  }
}

///|
/// Return the workspace directory path (`$HOME/work`).
pub fn workspace_dir() -> String {
  @path.Path(home_dir()).join(@path.Path("work")).to_string()
}

///|
/// Return the worktrees directory path (`$HOME/work/worktrees`).
pub fn worktree_dir() -> String {
  @path.Path(workspace_dir()).join(@path.Path("worktrees")).to_string()
}

///|
/// Return the configuration directory path (`$HOME/.config/ctt`).
pub fn config_dir() -> String {
  @path.Path(home_dir()).join(@path.Path(".config/ctt")).to_string()
}

///|
/// Validate that the worktree directory exists. Raises on failure.
pub fn validate() -> Unit raise {
  let dir = worktree_dir()
  if not(@fs.path_exists(dir)) {
    raise @builtin.Failure("Worktree directory not found: \{dir}")
  }
}

///|
/// Application-level configuration paths.
pub(all) struct AppConfig {
  workspace_dir : String
  config_dir : String
}

///|
/// Returns the worktree base directory derived from the workspace directory.
pub fn worktree_dir(cfg : AppConfig) -> String {
  @task.worktree_dir(cfg.workspace_dir)
}

///|
/// Available CLI subcommands.
pub(all) enum Command {
  Ls
  Open
  Status
  Done
  New
}

///|
/// Parsed CLI input containing the resolved command and its parameters.
pub(all) struct CommandInput {
  command : Command
  params : Array[String]
}

///|
/// Trait for executable commands. Each command struct implements this to define its behavior.
pub(open) trait Runnable {
  async run(Self) -> Unit raise
}

///|
/// Dependency container holding all service interfaces used by commands.
pub(all) struct Services {
  selector : &@ports.ItemSelector
  prompter : &@ports.UserPrompter
  repo_query : &@ports.RepositoryQuery
  repo_mutator : &@ports.RepositoryMutator
  pr : &@ports.PullRequestService
  session : &@ports.SessionManager
  editor : &@ports.EditorLauncher
  fs : &@ports.FileSystem
  repo_finder : &@ports.RepositoryFinder
  tasks : &@task.TaskRepository
}

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

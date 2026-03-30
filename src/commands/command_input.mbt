///|
pub(all) enum Command {
  Ls
  Open
  Status
  Done
  New
}

///|
pub(all) struct CommandInput {
  command : Command
  params : Array[String]
}

///|
pub(open) trait Runnable {
  async run(Self) -> Unit raise
}

///|
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
pub(all) struct AppConfig {
  workspace_dir : String
  config_dir : String
}

///|
pub fn worktree_dir(cfg : AppConfig) -> String {
  @task.worktree_dir(cfg.workspace_dir)
}

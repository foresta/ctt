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

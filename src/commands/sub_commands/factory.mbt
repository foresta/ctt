///|
/// Create a HelpCommand as a Runnable.
pub fn new_help() -> &@ports.Runnable {
  HelpCommand::{}
}

///|
/// Create an LsCommand as a Runnable.
pub fn new_ls(tasks : &@task.TaskRepository) -> &@ports.Runnable {
  LsCommand::{ tasks, }
}

///|
/// Create an OpenCommand as a Runnable.
pub fn new_open(
  editor : &@ports.EditorLauncher,
  tasks : &@task.TaskRepository
) -> &@ports.Runnable {
  OpenCommand::{ editor, tasks }
}

///|
/// Create a StatusCommand as a Runnable.
pub fn new_status(
  repo : &@ports.RepositoryQuery,
  tasks : &@task.TaskRepository,
  params : Array[String]
) -> &@ports.Runnable {
  StatusCommand::{ repo, tasks, params }
}

///|
/// Create a DoneCommand as a Runnable.
pub fn new_done(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  session : &@ports.SessionManager,
  tasks : &@task.TaskRepository
) -> &@ports.Runnable {
  DoneCommand::{ repo_query, repo_mutator, session, tasks }
}

///|
/// Create a NewCommand as a Runnable.
pub fn new_new(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  repo_finder : &@ports.RepositoryFinder,
  workspace_dir : String,
  config_dir : String
) -> &@ports.Runnable {
  NewCommand::{
    repo_query, repo_mutator, editor, fs, repo_finder,
    workspace_dir, config_dir,
  }
}

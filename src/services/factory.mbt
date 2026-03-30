///|
pub fn new_selector() -> &@ports.ItemSelector {
  FzfSelector::{}
}

///|
pub fn new_prompter() -> &@ports.UserPrompter {
  ShellPrompter::{}
}

///|
pub fn new_repo_query() -> &@ports.RepositoryQuery {
  GitCli::{}
}

///|
pub fn new_repo_mutator() -> &@ports.RepositoryMutator {
  GitCli::{}
}

///|
pub fn new_pr_service() -> &@ports.PullRequestService {
  GhCli::{}
}

///|
pub fn new_session_manager() -> &@ports.SessionManager {
  TmuxSession::{}
}

///|
pub fn new_editor() -> &@ports.EditorLauncher {
  NvimEditor::{}
}

///|
pub fn new_filesystem() -> &@ports.FileSystem {
  OsFileSystem::{}
}

///|
pub fn new_repo_finder() -> &@ports.RepositoryFinder {
  FindCommandFinder::{}
}

///|
pub fn new_task_repository(
  fs : &@ports.FileSystem,
  workspace_dir : String
) -> &@task.TaskRepository {
  OsTaskRepository::{ fs, workspace_dir }
}

///|
/// Create an ItemSelector backed by fzf.
pub fn new_selector() -> &@ports.ItemSelector {
  FzfSelector::{}
}

///|
/// Create a UserPrompter backed by shell stdin.
pub fn new_prompter() -> &@ports.UserPrompter {
  ShellPrompter::{}
}

///|
/// Create a RepositoryQuery backed by the git CLI.
pub fn new_repo_query() -> &@ports.RepositoryQuery {
  GitCli::{}
}

///|
/// Create a RepositoryMutator backed by the git CLI.
pub fn new_repo_mutator() -> &@ports.RepositoryMutator {
  GitCli::{}
}

///|
/// Create a PullRequestService backed by the gh CLI.
pub fn new_pr_service() -> &@ports.PullRequestService {
  GhCli::{}
}

///|
/// Create a SessionManager backed by tmux.
pub fn new_session_manager() -> &@ports.SessionManager {
  TmuxSession::{}
}

///|
/// Create an EditorLauncher backed by nvim with Claude Code.
pub fn new_editor() -> &@ports.EditorLauncher {
  NvimEditor::{}
}

///|
/// Create a FileSystem backed by OS-level file operations.
pub fn new_filesystem() -> &@ports.FileSystem {
  OsFileSystem::{}
}

///|
/// Create a RepositoryFinder backed by the find command.
pub fn new_repo_finder() -> &@ports.RepositoryFinder {
  FindCommandFinder::{}
}

///|
/// Create a TaskRepository that scans the worktree directory on the filesystem.
pub fn new_task_repository(
  fs : &@ports.FileSystem,
  workspace_dir : String
) -> &@task.TaskRepository {
  OsTaskRepository::{ fs, workspace_dir }
}

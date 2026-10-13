///|
/// Dependency container holding all service interfaces used by commands.
pub(all) struct Services {
  selector : &@ports.ItemSelector
  prompter : &@ports.UserPrompter
  vcs : &@ports.VCS
  workspace : &@ports.WorkspaceManager
  fs : &@ports.FileSystem
  worktrees : &@ports.WorktreeRepository
}

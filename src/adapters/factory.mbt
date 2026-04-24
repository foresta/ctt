///|
/// Create an ItemSelector backed by fzf.
pub fn new_selector() -> &@ports.ItemSelector {
  FzfSelector::{}
}

///|
/// Create a Console that provides both Renderer and UserPrompter via stdout/stdin.
pub fn new_console() -> Console {
  Console::{}
}

///|
/// Create a VCS backed by the git CLI.
pub fn new_vcs() -> &@ports.VCS {
  GitCli::{}
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


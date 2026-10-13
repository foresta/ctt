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
/// Create the WorkspaceManager selected by the user config.
pub fn new_workspace_manager(
  cfg : @config.CttConfig
) -> &@ports.WorkspaceManager {
  match cfg.multiplexer {
    Herdr =>
      (HerdrWorkspace::{ agent_command: cfg.herdr.agent_command } : &@ports.WorkspaceManager)
    Tmux => (TmuxWorkspace::{} : &@ports.WorkspaceManager)
  }
}

///|
/// Create a FileSystem backed by OS-level file operations.
pub fn new_filesystem() -> &@ports.FileSystem {
  OsFileSystem::{}
}


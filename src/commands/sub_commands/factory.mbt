///|
/// Create a HelpCommand as a Runnable.
pub fn new_help() -> &@ports.Runnable {
  HelpCommand::{}
}

///|
/// Create a VersionCommand as a Runnable.
pub fn new_version() -> &@ports.Runnable {
  VersionCommand::{}
}

///|
/// Create an LsCommand as a Runnable.
pub fn new_ls(worktrees : &@ports.WorktreeRepository) -> &@ports.Runnable {
  LsCommand::{ worktrees, }
}

///|
/// Create an OpenCommand as a Runnable.
pub fn new_open(
  editor : &@ports.EditorLauncher,
  worktrees : &@ports.WorktreeRepository
) -> &@ports.Runnable {
  OpenCommand::{ editor, worktrees }
}

///|
/// Create a StatusCommand as a Runnable.
pub fn new_status(
  vcs : &@ports.VCS,
  worktrees : &@ports.WorktreeRepository,
  params : Array[String]
) -> &@ports.Runnable {
  StatusCommand::{ vcs, worktrees, params }
}

///|
/// Create a DoneCommand as a Runnable.
pub fn new_done(
  vcs : &@ports.VCS,
  session : &@ports.SessionManager,
  worktrees : &@ports.WorktreeRepository
) -> &@ports.Runnable {
  DoneCommand::{ vcs, session, worktrees }
}

///|
/// Create a NewCommand as a Runnable.
pub fn new_new(
  discovery : @domain.DiscoveryService,
  worktree : @domain.WorktreeService,
  vcs : &@ports.VCS,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  workspace_dir : String
) -> &@ports.Runnable {
  NewCommand::{
    discovery, worktree, vcs, editor, fs,
    workspace_dir,
  }
}

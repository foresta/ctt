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
/// Create a UsageErrorCommand as a Runnable.
pub fn new_usage_error(message : String) -> &@ports.Runnable {
  UsageErrorCommand::{ message, }
}

///|
/// Create an LsCommand as a Runnable.
pub fn new_ls(worktrees : &@ports.WorktreeRepository) -> &@ports.Runnable {
  LsCommand::{ worktrees, }
}

///|
/// Create an OpenCommand as a Runnable.
pub fn new_open(
  workspace : &@ports.WorkspaceManager,
  worktrees : &@ports.WorktreeRepository,
  worktree : @domain.WorktreeService,
  opts : OpenOptions
) -> &@ports.Runnable {
  OpenCommand::{ workspace, worktrees, worktree, opts }
}

///|
/// Create a StatusCommand as a Runnable.
pub fn new_status(
  vcs : &@ports.VCS,
  worktrees : &@ports.WorktreeRepository,
  opts : StatusOptions
) -> &@ports.Runnable {
  StatusCommand::{ vcs, worktrees, opts }
}

///|
/// Create a DoneCommand as a Runnable.
pub fn new_done(
  vcs : &@ports.VCS,
  workspace : &@ports.WorkspaceManager,
  worktrees : &@ports.WorktreeRepository,
  worktree : @domain.WorktreeService,
  opts : DoneOptions
) -> &@ports.Runnable {
  DoneCommand::{ vcs, workspace, worktrees, worktree, opts }
}

///|
/// Create a NewCommand as a Runnable.
pub fn new_new(
  discovery : @domain.DiscoveryService,
  worktree : @domain.WorktreeService,
  vcs : &@ports.VCS,
  workspace : &@ports.WorkspaceManager,
  fs : &@ports.FileSystem,
  workspace_dir : String,
  prompt_template : String,
  opts : NewOptions
) -> &@ports.Runnable {
  NewCommand::{
    discovery, worktree, vcs, workspace, fs,
    workspace_dir, prompt_template, opts,
  }
}

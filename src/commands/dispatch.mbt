///|
/// Routes a parsed command input to the corresponding command implementation.
pub fn dispatch(
  input : CommandInput,
  svc : Services,
  cfg : AppConfig
) -> &@ports.Runnable {
  match input.command {
    Help => @sub_commands.new_help()
    Version => @sub_commands.new_version()
    Usage(message) => @sub_commands.new_usage_error(message)
    Ls => @sub_commands.new_ls(svc.worktrees)
    Open(opts) => @sub_commands.new_open(svc.workspace, svc.worktrees, opts)
    Status(opts) => @sub_commands.new_status(svc.vcs, svc.worktrees, opts)
    Done(opts) =>
      @sub_commands.new_done(svc.vcs, svc.workspace, svc.worktrees, opts)
    New(opts) => {
      let discovery = @domain.DiscoveryService::{ vcs: svc.vcs, fs: svc.fs }
      let worktree = @domain.WorktreeService::{
        vcs: svc.vcs, fs: svc.fs, config_dir: cfg.config_dir,
      }
      @sub_commands.new_new(
        discovery, worktree, svc.vcs, svc.workspace, svc.fs,
        cfg.workspace_dir, opts,
      )
    }
  }
}

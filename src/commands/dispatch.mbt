///|
/// Routes a parsed command input to the corresponding command implementation.
pub fn dispatch(
  input : CommandInput,
  svc : Services,
  cfg : AppConfig
) -> &@ports.Runnable {
  match input.command {
    Help => @sub_commands.new_help()
    Ls => @sub_commands.new_ls(svc.worktrees)
    Open => @sub_commands.new_open(svc.editor, svc.worktrees)
    Status =>
      @sub_commands.new_status(svc.vcs, svc.worktrees, input.params)
    Done =>
      @sub_commands.new_done(svc.vcs, svc.session, svc.worktrees)
    New => {
      let discovery = @domain.DiscoveryService::{ vcs: svc.vcs, fs: svc.fs }
      let worktree = @domain.WorktreeService::{
        vcs: svc.vcs, fs: svc.fs, config_dir: cfg.config_dir,
      }
      @sub_commands.new_new(
        discovery, worktree, svc.vcs, svc.editor, svc.fs,
        cfg.workspace_dir,
      )
    }
  }
}

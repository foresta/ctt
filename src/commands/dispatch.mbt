///|
/// Routes a parsed command input to the corresponding command implementation.
pub fn dispatch(
  input : CommandInput,
  svc : Services,
  cfg : AppConfig
) -> &@ports.Runnable {
  match input.command {
    Ls => @sub_commands.new_ls(svc.tasks)
    Open => @sub_commands.new_open(svc.editor, svc.tasks)
    Status =>
      @sub_commands.new_status(svc.repo_query, svc.tasks, input.params)
    Done =>
      @sub_commands.new_done(
        svc.repo_query, svc.repo_mutator, svc.session, svc.tasks,
      )
    New =>
      @sub_commands.new_new(
        svc.repo_query, svc.repo_mutator, svc.editor, svc.fs,
        svc.repo_finder, cfg.workspace_dir, cfg.config_dir,
      )
  }
}

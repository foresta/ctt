///|
/// Constructs all service implementations and returns them with the app config.
fn resolve_dependencies(
  cfg : @commands.AppConfig
) -> (@commands.Services, @commands.AppConfig, @adapters.Console) {
  let fs = @adapters.new_filesystem()
  let console = @adapters.new_console()
  let svc = @commands.Services::{
    selector: @adapters.new_selector(),
    prompter: console,
    vcs: @adapters.new_vcs(),
    session: @adapters.new_session_manager(),
    editor: @adapters.new_editor(),
    fs,
    worktrees: @services.new_worktree_repository(fs, cfg.workspace_dir),
  }
  (svc, cfg, console)
}

///|
/// Entry point: parses CLI args, validates config, wires dependencies, and runs the dispatched command.
async fn main {
  let input = @cli.parse(@env.args())
  try {
    @config.validate()
  } catch {
    err => {
      println("Error: \{err}")
      return
    }
  }
  let cfg = @commands.AppConfig::{
    workspace_dir: @config.workspace_dir(),
    config_dir: @config.config_dir(),
  }
  let (svc, cfg, console) = resolve_dependencies(cfg)
  let command = @commands.dispatch(input, svc, cfg)
  let result = command.run()
  @interpreter.run(result, console, svc.selector, svc.prompter)
}

///|
/// Constructs all service implementations and returns them with the app config.
fn resolve_dependencies(
  cfg : @commands.AppConfig,
  ctt_cfg : @config.CttConfig
) -> (@commands.Services, @commands.AppConfig, @adapters.Console) {
  let fs = @adapters.new_filesystem()
  let console = @adapters.new_console()
  let svc = @commands.Services::{
    selector: @adapters.new_selector(),
    prompter: console,
    vcs: @adapters.new_vcs(),
    workspace: @adapters.new_workspace_manager(ctt_cfg),
    fs,
    worktrees: @services.new_worktree_repository(fs, cfg.workspace_dir),
  }
  (svc, cfg, console)
}

///|
/// Entry point: parses CLI args, loads config, wires dependencies, and runs the dispatched command.
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
  // Only commands that open or close a workspace need config.toml, so a
  // broken config never blocks help / version / ls / status.
  let ctt_cfg = match input.command {
    New | Open | Done =>
      match @config.load_config() {
        Ok(c) => c
        Err(e) => {
          println("Error: \{e}")
          return
        }
      }
    _ => @config.CttConfig::default()
  }
  let cfg = @commands.AppConfig::{
    workspace_dir: @config.workspace_dir(),
    config_dir: @config.config_dir(),
  }
  let (svc, cfg, console) = resolve_dependencies(cfg, ctt_cfg)
  let command = @commands.dispatch(input, svc, cfg)
  let result = command.run()
  @interpreter.run(result, console, svc.selector, svc.prompter)
}

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
/// Read `--context-file` (or stdin for `-`) into `NewOptions.context` so the
/// command layer only deals with the context text.
async fn resolve_context_file(
  input : @commands.CommandInput
) -> Result[@commands.CommandInput, String] {
  guard input.command is New(opts) && opts.context_file is Some(path) else {
    return Ok(input)
  }
  let text = match @adapters.read_text_source(path) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  if text.trim().to_owned() == "" {
    return Err("context from " + path + " is empty")
  }
  Ok({ command: New({ ..opts, context: Some(text), context_file: None }) })
}

///|
/// Entry point: parses CLI args, loads config, wires dependencies, and runs the dispatched command.
async fn main {
  let input = match resolve_context_file(@cli.parse(@env.args())) {
    Ok(i) => i
    Err(e) => {
      println("Error: \{e}")
      @sys.exit(1)
      return
    }
  }
  try {
    @config.validate()
  } catch {
    err => {
      println("Error: \{err}")
      @sys.exit(1)
    }
  }
  // Only commands that open or close a workspace need config.toml, so a
  // broken config never blocks help / version / ls / status.
  let ctt_cfg = match input.command {
    New(_) | Open(_) | Done(_) =>
      match @config.load_config() {
        Ok(c) => c
        Err(e) => {
          println("Error: \{e}")
          @sys.exit(1)
          return
        }
      }
    _ => @config.CttConfig::default()
  }
  let cfg = @commands.AppConfig::{
    workspace_dir: @config.workspace_dir(),
    config_dir: @config.config_dir(),
    prompt_template: ctt_cfg.agent.prompt_template,
  }
  let (svc, cfg, console) = resolve_dependencies(cfg, ctt_cfg)
  let command = @commands.dispatch(input, svc, cfg)
  let result = command.run()
  let ok = @interpreter.run(result, console, svc.selector, svc.prompter)
  if !ok {
    @sys.exit(1)
  }
}

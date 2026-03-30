///|
/// Constructs all service implementations and returns them with the app config.
fn resolve_dependencies(
  cfg : @commands.AppConfig
) -> (@commands.Services, @commands.AppConfig) {
  let fs = @services.new_filesystem()
  let svc = @commands.Services::{
    selector: @services.new_selector(),
    prompter: @services.new_prompter(),
    repo_query: @services.new_repo_query(),
    repo_mutator: @services.new_repo_mutator(),
    pr: @services.new_pr_service(),
    session: @services.new_session_manager(),
    editor: @services.new_editor(),
    fs,
    repo_finder: @services.new_repo_finder(),
    tasks: @services.new_task_repository(fs, cfg.workspace_dir),
  }
  (svc, cfg)
}

///|
/// Entry point: parses CLI args, validates config, wires dependencies, and runs the dispatched command.
async fn main {
  let input = try {
    @cli.parse(@env.args())
  } catch {
    _ => return
  }
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
  let (svc, cfg) = resolve_dependencies(cfg)
  let command = @commands.dispatch(input, svc, cfg)
  try {
    command.run()
  } catch {
    err => println("Error: \{err}")
  }
}

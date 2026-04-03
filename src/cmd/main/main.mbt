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
/// Interprets a CommandResult tree, performing actual I/O.
/// Delegates output to the Renderer and interaction to ItemSelector/UserPrompter.
async fn render(
  result : @ports.CommandResult,
  renderer : &@ports.Renderer,
  selector : &@ports.ItemSelector,
  prompter : &@ports.UserPrompter
) -> Unit {
  match result {
    Lines(lines) => renderer.print_lines(lines)
    Table(rows) => renderer.print_table(rows)
    Empty => ()
    Error(msg) => renderer.print_error(msg)
    Confirm(message~, prompt~, on_yes~) => {
      renderer.print_lines(message)
      match prompter.confirm(prompt=prompt) {
        Ok(true) => render(on_yes(), renderer, selector, prompter)
        _ => renderer.print_cancelled()
      }
    }
    Select(message~, items~, prompt~, on_select~) => {
      renderer.print_lines(message)
      match selector.select(items=items, prompt=prompt) {
        Ok(Some(selected)) =>
          render(on_select(selected), renderer, selector, prompter)
        _ => renderer.print_cancelled()
      }
    }
  }
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
  let (svc, cfg) = resolve_dependencies(cfg)
  let command = @commands.dispatch(input, svc, cfg)
  let renderer = @services.new_console_renderer()
  let result = command.run()
  render(result, renderer, svc.selector, svc.prompter)
}

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
/// Pads a string with trailing spaces to reach the given width.
fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let buf = StringBuilder::new()
  buf.write_string(s)
  for i = len; i < width; i = i + 1 {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Renders a table as column-aligned text to stdout.
fn print_table(rows : Array[Array[String]]) -> Unit {
  let col_count = rows[0].length()
  let widths = Array::make(col_count, 0)
  for row in rows {
    for i, cell in row {
      if cell.length() > widths[i] {
        widths[i] = cell.length()
      }
    }
  }
  for row in rows {
    let buf = StringBuilder::new()
    for i, cell in row {
      if i > 0 {
        buf.write_string("  ")
      }
      if i < col_count - 1 {
        buf.write_string(pad_right(cell, widths[i]))
      } else {
        buf.write_string(cell)
      }
    }
    println(buf.to_string())
  }
}

///|
/// Interprets a CommandResult tree, performing actual I/O.
/// This is the only place in the application that calls println.
async fn render(
  result : @ports.CommandResult,
  selector : &@ports.ItemSelector,
  prompter : &@ports.UserPrompter
) -> Unit {
  match result {
    Lines(lines) => lines.each(fn(l) { println(l) })
    Table(rows) => print_table(rows)
    Empty => ()
    Confirm(message~, prompt~, on_yes~) => {
      message.each(fn(l) { println(l) })
      match prompter.confirm(prompt=prompt) {
        Ok(true) => render(on_yes(), selector, prompter)
        _ => println("Cancelled.")
      }
    }
    Select(message~, items~, prompt~, on_select~) => {
      message.each(fn(l) { println(l) })
      match selector.select(items=items, prompt=prompt) {
        Ok(Some(selected)) => render(on_select(selected), selector, prompter)
        _ => println("Cancelled.")
      }
    }
  }
}

///|
/// Entry point: parses CLI args, validates config, wires dependencies, and runs the dispatched command.
async fn main {
  let input = @cli.parse(@env.args())
  // Help doesn't need config validation or DI
  if input.command == Help {
    let help = @sub_commands.new_help()
    let result = try { help.run() } catch { _ => return }
    render(result, @services.new_selector(), @services.new_prompter())
    return
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
  let result = try {
    command.run()
  } catch {
    err => {
      println("Error: \{err}")
      return
    }
  }
  render(result, svc.selector, svc.prompter)
}

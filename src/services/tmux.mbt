///|
/// Adapter that implements the SessionManager port using tmux.
pub(all) struct TmuxSession {}

///|
/// Return true if running inside a tmux session.
impl @ports.SessionManager for TmuxSession with is_active(self) {
  let _ = self
  match @sys.get_env_var("TMUX") {
    Some(v) => v != ""
    None => false
  }
}

///|
/// List all window names in the current tmux session.
impl @ports.SessionManager for TmuxSession with list_windows(self) {
  let _ = self
  let (status, output) = run_and_collect_merged(
    "tmux",
    ["list-windows", "-F", "#{window_name}"],
  )
  if status != 0 {
    return Ok([])
  }
  let text = output.trim_end().to_string()
  if text == "" {
    return Ok([])
  }
  Ok(text.split("\n").map(fn(s) { s.to_string() }).collect())
}

///|
/// Create a new tmux window with the specified name, directory, and command.
impl @ports.SessionManager for TmuxSession with create_window(self, name~, cwd~, command~) {
  let _ = self
  let _ = @process.run("tmux", ["new-window", "-n", name, "-c", cwd, command])

  Ok(())
}

///|
/// Kill a tmux window by name.
impl @ports.SessionManager for TmuxSession with kill_window(self, name~) {
  let _ = self
  let _ = @process.run("tmux", ["kill-window", "-t", name])

  Ok(())
}

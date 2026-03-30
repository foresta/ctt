///|
/// Adapter that implements the SessionManager port using tmux.
pub(all) struct TmuxSession {}

///|
/// Return true if running inside a tmux session.
impl @ports.SessionManager for TmuxSession with is_active(self) {
  let _ = self
  is_in_tmux()
}

///|
/// List all window names in the current tmux session.
impl @ports.SessionManager for TmuxSession with list_windows(self) {
  let _ = self
  Ok(tmux_list_windows())
}

///|
/// Create a new tmux window with the specified name, directory, and command.
impl @ports.SessionManager for TmuxSession with create_window(self, name~, cwd~, command~) {
  let _ = self
  tmux_new_window(name, cwd, command)
  Ok(())
}

///|
/// Kill a tmux window by name.
impl @ports.SessionManager for TmuxSession with kill_window(self, name~) {
  let _ = self
  tmux_kill_window(name)
  Ok(())
}

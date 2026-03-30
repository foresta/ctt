///|
pub(all) struct TmuxSession {}

///|
impl @ports.SessionManager for TmuxSession with is_active(self) {
  let _ = self
  is_in_tmux()
}

///|
impl @ports.SessionManager for TmuxSession with list_windows(self) {
  let _ = self
  Ok(tmux_list_windows())
}

///|
impl @ports.SessionManager for TmuxSession with create_window(self, name~, cwd~, command~) {
  let _ = self
  tmux_new_window(name, cwd, command)
  Ok(())
}

///|
impl @ports.SessionManager for TmuxSession with kill_window(self, name~) {
  let _ = self
  tmux_kill_window(name)
  Ok(())
}

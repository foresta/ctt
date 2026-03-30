///|
/// Create a new tmux window with the given name, working directory, and command.
pub async fn tmux_new_window(
  name : String,
  cwd : String,
  command : String
) -> Unit {
  let _ = @process.run(
    "tmux",
    ["new-window", "-n", name, "-c", cwd, command],
  )

}

///|
/// List all tmux window names in the current session.
pub async fn tmux_list_windows() -> Array[String] {
  let (status, output) = @process.collect_output_merged(
    "tmux",
    ["list-windows", "-F", "#{window_name}"],
  )
  if status != 0 {
    return []
  }
  let text = output.text().trim_end().to_string()
  if text == "" {
    return []
  }
  text.split("\n").map(fn(s) { s.to_string() }).collect()
}

///|
/// Kill a tmux window by name.
pub async fn tmux_kill_window(name : String) -> Unit {
  let _ = @process.run("tmux", ["kill-window", "-t", name])

}

///|
/// Check whether the current process is running inside a tmux session.
pub fn is_in_tmux() -> Bool {
  match @sys.get_env_var("TMUX") {
    Some(v) => v != ""
    None => false
  }
}

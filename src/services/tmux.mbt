///|
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
pub async fn tmux_kill_window(name : String) -> Unit {
  let _ = @process.run("tmux", ["kill-window", "-t", name])

}

///|
pub fn is_in_tmux() -> Bool {
  match @sys.get_env_var("TMUX") {
    Some(v) => v != ""
    None => false
  }
}

///|
/// Adapter that implements WorkspaceManager with tmux: one window per task
/// running nvim with the ClaudeCode plugin.
pub(all) struct TmuxWorkspace {}

///|
/// Return true if running inside a tmux session.
fn in_tmux() -> Bool {
  match @env.get_env_var("TMUX") {
    Some(v) => v != ""
    None => false
  }
}

///|
/// List all window names in the current tmux session.
async fn tmux_list_windows() -> Array[String] {
  let (status, output) = @proc.exec_cmd(
    "tmux",
    ["list-windows", "-F", "#{window_name}"],
  )
  if status != 0 {
    return []
  }
  let text = output.trim_end().to_owned()
  if text == "" {
    return []
  }
  text.split("\n").map(fn(s) { s.to_owned() }).collect()
}

///|
/// Run a tmux command, mapping a non-zero exit status to Err.
async fn tmux_run(args : Array[String]) -> Result[Unit, String] {
  let status = @process.run("tmux", args)
  if status != 0 {
    Err("tmux " + args[0] + " failed (exit \{status})")
  } else {
    Ok(())
  }
}

///|
/// Open nvim with Claude Code in a new tmux window (or select the task's
/// window when it already exists). Outside tmux, nvim runs in the current
/// terminal when focus is requested; `focus=false` is an error there.
impl @ports.WorkspaceManager for TmuxWorkspace with open(self, repo_name~, branch~, workdir~, continue_session~, focus~, prompt_file~) {
  // The ClaudeCode nvim plugin cannot take an initial prompt.
  let _ = (self, prompt_file)
  let tmux_window_name = "\{repo_name}__\{branch}"
  let terminal_title = "Claude: \{repo_name} [\{branch}]"
  let claude_cmd = if continue_session {
    "ClaudeCode --continue"
  } else {
    "ClaudeCode"
  }
  if in_tmux() {
    if tmux_list_windows().contains(tmux_window_name) {
      if !focus {
        return Ok(Reused)
      }
      println("Selecting existing tmux window...")
      return match tmux_run(["select-window", "-t", tmux_window_name]) {
        Ok(_) => Ok(Reused)
        Err(e) => Err(e)
      }
    }
    println("Opening in new tmux window...")
    let cmd = "printf '\\033]0;\{terminal_title}\\007'; nvim . -c \"\{claude_cmd}\""
    let args = ["new-window", "-n", tmux_window_name, "-c", workdir]
    if !focus {
      args.push("-d")
    }
    args.push(cmd)
    match tmux_run(args) {
      Ok(_) => Ok(Created)
      Err(e) => Err(e)
    }
  } else if !focus {
    Err("not inside tmux: cannot open a window without focus")
  } else {
    println("Warning: not in tmux session. Opening in current terminal...")
    let _ = @process.run("nvim", [".", "-c", claude_cmd], cwd=workdir)

    Ok(Created)
  }
}

///|
impl @ports.WorkspaceManager for TmuxWorkspace with supports_prompt(self) {
  let _ = self
  false
}

///|
/// Whether the current tmux window is the task's window.
impl @ports.WorkspaceManager for TmuxWorkspace with is_current(self, name~) {
  let _ = self
  if !in_tmux() {
    return Ok(false)
  }
  // Ask about ctt's own pane, not the client's active window.
  let args = match @env.get_env_var("TMUX_PANE") {
    Some(pane) if pane != "" => ["display-message", "-p", "-t", pane, "#{window_name}"]
    _ => ["display-message", "-p", "#{window_name}"]
  }
  let (status, output) = @proc.exec_cmd("tmux", args)
  Ok(status == 0 && output.trim_end().to_owned() == name)
}

///|
/// Kill the task's window shortly after this process exits.
impl @ports.WorkspaceManager for TmuxWorkspace with close_later(self, name~) {
  let _ = self
  if !in_tmux() || !tmux_list_windows().contains(name) {
    return Ok(false)
  }
  let script = @shell.detached_after(
    @shell.CLOSE_DELAY_SECONDS,
    "tmux kill-window -t " + @shell.quote(name),
  )
  let (status, _) = @proc.exec_cmd("sh", ["-c", script], cwd="/")
  if status != 0 {
    return Err("failed to schedule window close")
  }
  Ok(true)
}

///|
/// Kill the tmux window named `name` if it exists in the current session.
impl @ports.WorkspaceManager for TmuxWorkspace with close(self, name~) {
  let _ = self
  if !in_tmux() {
    return Ok(false)
  }
  if !tmux_list_windows().contains(name) {
    return Ok(false)
  }
  match tmux_run(["kill-window", "-t", name]) {
    Ok(_) => Ok(true)
    Err(e) => Err(e)
  }
}

///|
/// Adapter that implements the EditorLauncher port using nvim with Claude Code.
pub(all) struct NvimEditor {}

///|
/// Open nvim with Claude Code in a tmux window or the current terminal.
impl @ports.EditorLauncher for NvimEditor with open(self, repo_name~, workdir~, branch~, continue_session~) {
  let _ = self
  let tmux_window_name = "\{repo_name}__\{branch}"
  let terminal_title = "Claude: \{repo_name} [\{branch}]"
  let claude_cmd = if continue_session {
    "ClaudeCode --continue"
  } else {
    "ClaudeCode"
  }
  let in_tmux = match @sys.get_env_var("TMUX") {
    Some(v) => v != ""
    None => false
  }
  if in_tmux {
    println("Opening in new tmux window...")
    let cmd = "printf '\\033]0;\{terminal_title}\\007'; nvim . -c \"\{claude_cmd}\""
    let _ = @process.run(
      "tmux",
      ["new-window", "-n", tmux_window_name, "-c", workdir, cmd],
    )

  } else {
    println("Warning: not in tmux session. Opening in current terminal...")
    let _ = @process.run("nvim", [".", "-c", claude_cmd], cwd=workdir)

  }
  Ok(())
}

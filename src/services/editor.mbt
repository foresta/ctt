///|
/// Open nvim with Claude Code in a tmux window (or current terminal if not in tmux).
pub async fn open_editor(
  repo_name : String,
  workdir : String,
  branch : String,
  continue_session~ : Bool = false
) -> Unit {
  let tmux_window_name = "\{repo_name}__\{branch}"
  let terminal_title = "Claude: \{repo_name} [\{branch}]"
  let claude_cmd = if continue_session { "ClaudeCode --continue" } else { "ClaudeCode" }
  if is_in_tmux() {
    println("Opening in new tmux window...")
    let cmd = "printf '\\033]0;\{terminal_title}\\007'; nvim . -c \"\{claude_cmd}\""
    tmux_new_window(tmux_window_name, workdir, cmd)
  } else {
    println("Warning: not in tmux session. Opening in current terminal...")
    // For non-tmux, exec nvim directly
    let _ = @process.run(
      "nvim",
      [".", "-c", claude_cmd],
      cwd=workdir,
    )

  }
}

///|
/// Displays usage information.
pub(all) struct HelpCommand {}

///|
/// Returns usage text as Lines.
impl @ports.Runnable for HelpCommand with run(self) {
  let _ = self
  @ports.Lines(
    [
      "Usage: ctt <command>",
      "",
      "Commands:",
      "  new    Create a worktree and launch ClaudeCode",
      "  ls     List active tasks",
      "  open   Open a task in the editor",
      "  status Show task status (--all for all tasks)",
      "  done   Complete a task and remove its worktree",
    ],
  )
}

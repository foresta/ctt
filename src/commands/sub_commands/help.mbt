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
      "  ls     List active worktrees",
      "  open   Open a worktree in the editor",
      "  status Show worktree status (--all for all)",
      "  done   Complete and remove a worktree",
    ],
  )
}

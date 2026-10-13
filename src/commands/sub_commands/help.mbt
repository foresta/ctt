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
      "  new      Create a worktree and open it with Claude Code",
      "  ls       List active worktrees",
      "  open     Open a worktree in its workspace",
      "  status   Show worktree status",
      "  done     Complete and remove a worktree",
      "  version  Print version information",
      "",
      "Options (omit any to be asked interactively):",
      "  new    --repo <name|path> --branch <branch> [--base <branch>] [--no-focus]",
      "         [--context <text> | --context-file <path|-> | --context-url <url>]",
      "  open   [<repo>__<branch>] [--no-focus]",
      "  done   [<repo>__<branch>] [--yes] [--delete-branch]",
      "  status [--all | <repo>__<branch>]",
      "",
      "  --base          Create <branch> from this branch instead of checking it out",
      "  --context...    Task context for the agent's first prompt (asked only when the branch is chosen interactively)",
      "  --no-focus      Do not switch to the workspace",
      "  --yes           Skip the removal confirmation",
      "  --delete-branch Also delete the local branch (never forced)",
      "  -V, --version   Print version information",
      "",
      "Exit status is 1 on error or when a prompt is cancelled.",
    ],
  )
}

///|
/// Completes a worktree by removing it, closing its workspace and deleting its branch.
pub(all) struct DoneCommand {
  vcs : &@ports.VCS
  workspace : &@ports.WorkspaceManager
  worktrees : &@ports.WorktreeRepository
  worktree : @domain.WorktreeService
  opts : DoneOptions
}

///|
/// Pick the worktree (by name or interactively), then review and confirm.
impl @ports.Runnable for DoneCommand with run(self) {
  pick_worktree(
    self.worktrees, self.opts.name, "Select Worktree to Complete> ",
    async fn(wt) { self.review(wt) },
  )
}

///|
/// Show the worktree status, then remove it (after confirmation unless `--yes`).
async fn DoneCommand::review(
  self : DoneCommand,
  wt : @ports.Worktree
) -> @ports.CommandResult {
  let info = match self.vcs.get_worktree_status(name=wt.name, workdir=wt.workdir) {
    Ok(i) => i
    Err(e) => return @ports.Error(e)
  }
  let message : Array[String] = [
    "Worktree: " + info.name,
    info.to_row().join("\t"),
    "---",
  ]
  let confirm_prompt = match info.status {
    Merged | NoChanges => "Remove this worktree? [y/N] "
    InProgress => {
      message.push("Warning: uncommitted or unmerged changes exist.")
      "Are you sure you want to remove it? [y/N] "
    }
    PrOpen => {
      message.push("Warning: PR is still open.")
      "Are you sure you want to remove it? [y/N] "
    }
  }
  if self.opts.yes {
    return @ports.Then(
      first=@ports.Lines(message),
      next=async fn() { self.remove(wt) },
    )
  }
  @ports.Sequence([
    @ports.Lines(message),
    @ports.Confirm(
      prompt=confirm_prompt,
      on_yes=async fn() { self.remove(wt) },
    ),
  ])
}

///|
/// Post-confirm: close workspace, remove worktree, then handle the branch.
async fn DoneCommand::remove(
  self : DoneCommand,
  wt : @ports.Worktree
) -> @ports.CommandResult {
  let name = wt.name
  let output : Array[String] = []
  // Resolve the repository before the worktree directory disappears.
  let git_dir = match self.vcs.resolve_git_dir(workdir=wt.workdir) {
    Ok(d) => Some(d)
    Err(_) => None
  }
  // Close the workspace if one is open (non-fatal)
  match self.workspace.close(name=name) {
    Ok(true) => output.push("Closed workspace: " + name)
    Ok(false) => ()
    Err(e) => output.push("Warning: failed to close workspace: " + e)
  }
  match self.vcs.remove_worktree(workdir=wt.workdir) {
    Ok(_) => ()
    Err(e) => return @ports.Error("failed to remove worktree: " + e)
  }
  match self.worktree.remove_prompt(name) {
    Ok(true) => output.push("Removed task prompt")
    Ok(false) => ()
    Err(e) => output.push("Warning: " + e)
  }
  match self.branch_cleanup(git_dir, wt, output) {
    Some(interactive) => interactive
    None => {
      output.push("Completed: " + name)
      @ports.Lines(output)
    }
  }
}

///|
/// Branch handling after removal. Returns `None` when it finished (appending
/// to `output`), or the interactive confirmation flow that prints the
/// completion line itself.
async fn DoneCommand::branch_cleanup(
  self : DoneCommand,
  git_dir : String?,
  wt : @ports.Worktree,
  output : Array[String]
) -> @ports.CommandResult? {
  let git_dir = match git_dir {
    Some(d) if wt.branch != "" => d
    _ => return None
  }
  if !(self.vcs.branch_exists(git_dir=git_dir, branch=wt.branch) is Ok(true)) {
    return None
  }
  let vcs = self.vcs
  if self.opts.delete_branch {
    match vcs.delete_branch(git_dir=git_dir, branch=wt.branch, force=false) {
      Ok(_) => output.push("Deleted branch: " + wt.branch)
      Err(e) => {
        // git appends hint lines; the first line carries the reason.
        let reason = match e.find("\n") {
          Some(idx) => e[:idx].to_owned()
          None => e
        }
        output.push("Warning: branch '" + wt.branch + "' left in place: " + reason)
      }
    }
    return None
  }
  if self.opts.yes {
    return None
  }
  let name = wt.name
  Some(
    @ports.Sequence([
      @ports.Lines(output),
      @ports.Confirm(
        prompt="Delete local branch '" + wt.branch + "'? [y/N] ",
        on_yes=async fn() {
          done_delete_branch(vcs, git_dir, wt.branch, name)
        },
      ),
    ]),
  )
}

///|
/// Delete branch, with force retry on failure.
async fn done_delete_branch(
  vcs : &@ports.VCS,
  git_dir : String,
  branch : String,
  name : String
) -> @ports.CommandResult {
  match vcs.delete_branch(git_dir=git_dir, branch=branch, force=false) {
    Ok(_) => @ports.Lines(["Completed: " + name])
    Err(_) =>
      @ports.Sequence([
        @ports.Lines(["Warning: branch '" + branch + "' is not fully merged."]),
        @ports.Confirm(
          prompt="Force delete? [y/N] ",
          on_yes=async fn() {
            let _ = vcs.delete_branch(
              git_dir=git_dir,
              branch=branch,
              force=true,
            )
            @ports.Lines(["Completed: " + name])
          },
        ),
      ])
  }
}

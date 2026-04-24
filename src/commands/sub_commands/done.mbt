///|
/// Completes a worktree by removing it, optionally closing its tmux window and deleting its branch.
pub(all) struct DoneCommand {
  vcs : &@ports.VCS
  session : &@ports.SessionManager
  worktrees : &@ports.WorktreeRepository
}

///|
/// Returns a Select step to pick a worktree, then chains Confirm steps for cleanup.
impl @ports.Runnable for DoneCommand with run(self) {
  let worktree_list = match self.worktrees.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if worktree_list.is_empty() {
    return @ports.Lines(["No active worktrees."])
  }
  let names = worktree_list.map(fn(t) { t.name })
  let vcs = self.vcs
  let session = self.session
  @ports.Select(
    items=names,
    prompt="Select Worktree to Complete> ",
    on_select=async fn(name) {
      let wt = match worktree_list.iter().find_first(fn(t) { t.name == name }) {
        Some(t) => t
        None => return @ports.Lines(["Error: worktree not found"])
      }
      let info = match vcs.get_worktree_status(name=wt.name, workdir=wt.workdir) {
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
      @ports.Sequence([
        @ports.Lines(message),
        @ports.Confirm(
          prompt=confirm_prompt,
          on_yes=async fn() {
            done_after_confirm(vcs, session, wt, name)
          },
        ),
      ])
    },
  )
}

///|
/// Post-confirm: handle tmux window, remove worktree, delete branch.
async fn done_after_confirm(
  vcs : &@ports.VCS,
  session : &@ports.SessionManager,
  wt : @ports.Worktree,
  name : String
) -> @ports.CommandResult {
  let output : Array[String] = []
  // Kill tmux window if exists
  if session.is_active() {
    match session.list_windows() {
      Ok(windows) =>
        if windows.contains(name) {
          let _ = session.kill_window(name=name)
          output.push("Closed tmux window: " + name)
        }
      Err(_) => ()
    }
  }
  // Remove worktree
  match vcs.remove_worktree(workdir=wt.workdir) {
    Ok(_) => ()
    Err(e) => return @ports.Lines(["Error removing worktree: " + e])
  }
  // Delete local branch
  if wt.branch != "" {
    match vcs.branch_exists(workdir=wt.workdir, branch=wt.branch) {
      Ok(true) =>
        return @ports.Sequence([
          @ports.Lines(output),
          @ports.Confirm(
            prompt="Delete local branch '" + wt.branch + "'? [y/N] ",
            on_yes=async fn() {
              done_delete_branch(vcs, wt.workdir, wt.branch, name)
            },
          ),
        ])
      _ => ()
    }
  }
  output.push("Completed: " + name)
  @ports.Lines(output)
}

///|
/// Delete branch, with force retry on failure.
async fn done_delete_branch(
  vcs : &@ports.VCS,
  workdir : String,
  branch : String,
  name : String
) -> @ports.CommandResult {
  match vcs.delete_branch(workdir=workdir, branch=branch, force=false) {
    Ok(_) => @ports.Lines(["Completed: " + name])
    Err(_) =>
      @ports.Sequence([
        @ports.Lines(["Warning: branch '" + branch + "' is not fully merged."]),
        @ports.Confirm(
          prompt="Force delete? [y/N] ",
          on_yes=async fn() {
            let _ = vcs.delete_branch(
              workdir=workdir,
              branch=branch,
              force=true,
            )
            @ports.Lines(["Completed: " + name])
          },
        ),
      ])
  }
}

///|
/// Completes a task by removing its worktree, optionally closing its tmux window and deleting its branch.
pub(all) struct DoneCommand {
  repo_query : &@ports.RepositoryQuery
  repo_mutator : &@ports.RepositoryMutator
  session : &@ports.SessionManager
  tasks : &@task.TaskRepository
}

///|
/// Returns a Select step to pick a task, then chains Confirm steps for cleanup.
impl @ports.Runnable for DoneCommand with run(self) {
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if task_list.is_empty() {
    return @ports.Lines(["No active tasks."])
  }
  let names = task_list.map(fn(t) { t.name })
  let repo_query = self.repo_query
  let repo_mutator = self.repo_mutator
  let session = self.session
  @ports.Select(
    items=names,
    prompt="Select Task to Complete> ",
    accept_empty=false,
    on_select=async fn(name) {
      let t = match task_list.iter().find_first(fn(t) { t.name == name }) {
        Some(t) => t
        None => return @ports.Lines(["Error: task not found"])
      }
      let info = match repo_query.get_task_status(name=t.name, workdir=t.workdir) {
        Ok(i) => i
        Err(e) => return @ports.Error(e)
      }
      let message : Array[String] = [
        "Task: " + info.name,
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
      @ports.Sequence(
        @ports.Lines(message),
        @ports.Confirm(
          prompt=confirm_prompt,
          on_yes=async fn() {
            done_after_confirm(
              repo_query, repo_mutator, session, t, name,
            )
          },
        ),
      )
    },
  )
}

///|
/// Post-confirm: handle tmux window, remove worktree, delete branch.
async fn done_after_confirm(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  session : &@ports.SessionManager,
  t : @task.Task,
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
  let git_dir = match repo_query.common_dir(workdir=t.workdir) {
    Ok(d) => d
    Err(e) =>
      return @ports.Lines(["Error: failed to get git repository info: " + e])
  }
  match repo_mutator.remove_worktree(git_dir=git_dir, workdir=t.workdir) {
    Ok(_) => ()
    Err(e) => return @ports.Lines(["Error removing worktree: " + e])
  }
  // Delete local branch
  if t.branch != "" {
    match repo_query.branch_exists(git_dir=git_dir, branch=t.branch) {
      Ok(true) =>
        return @ports.Sequence(
          @ports.Lines(output),
          @ports.Confirm(
            prompt="Delete local branch '" + t.branch + "'? [y/N] ",
            on_yes=async fn() {
              done_delete_branch(
                repo_mutator, git_dir, t.branch, name,
              )
            },
          ),
        )
      _ => ()
    }
  }
  output.push("Task completed: " + name)
  @ports.Lines(output)
}

///|
/// Delete branch, with force retry on failure.
async fn done_delete_branch(
  repo_mutator : &@ports.RepositoryMutator,
  git_dir : String,
  branch : String,
  name : String
) -> @ports.CommandResult {
  match repo_mutator.delete_branch(git_dir=git_dir, branch=branch, force=false) {
    Ok(_) => @ports.Lines(["Task completed: " + name])
    Err(_) =>
      @ports.Sequence(
        @ports.Lines(["Warning: branch '" + branch + "' is not fully merged."]),
        @ports.Confirm(
          prompt="Force delete? [y/N] ",
          on_yes=async fn() {
            let _ = repo_mutator.delete_branch(
              git_dir=git_dir,
              branch=branch,
              force=true,
            )
            @ports.Lines(["Task completed: " + name])
          },
        ),
      )
  }
}

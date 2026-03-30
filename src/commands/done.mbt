///|
pub(all) struct DoneCommand {
  selector : &@ports.ItemSelector
  prompter : &@ports.UserPrompter
  repo_query : &@ports.RepositoryQuery
  repo_mutator : &@ports.RepositoryMutator
  session : &@ports.SessionManager
  tasks : &@task.TaskRepository
}

///|
impl Runnable for DoneCommand with run(self) {
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => { println("Error: \{e}"); return }
  }
  if task_list.is_empty() {
    println("No active tasks.")
    return
  }
  let names = task_list.map(fn(t) { t.name })
  let selected = match self.selector.select(
    items=names,
    prompt="Select Task to Complete> ",
  ) {
    Ok(s) => s
    Err(e) => { println("Error: \{e}"); return }
  }
  match selected {
    None => {
      println("Cancelled.")
      return
    }
    Some(name) => {
      let t = match task_list.iter().find_first(fn(t) { t.name == name }) {
        Some(t) => t
        None => { println("Error: task not found"); return }
      }
      println("Task: \{name}")
      let info = match self.repo_query.get_task_status(workdir=t.workdir) {
        Ok(i) => i
        Err(e) => { println("Error: \{e}"); return }
      }
      println(
        "\{format_status(info.status)}\t\{info.branch}\t\{info.uncommitted} changed\t\{info.commits_ahead} commits\t\{info.pr_url}",
      )
      println("---")
      // Confirm based on status
      let confirm_msg = match info.status {
        Merged | NoChanges => "Remove this worktree? [y/N] "
        InProgress => {
          println("Warning: uncommitted or unmerged changes exist.")
          "Are you sure you want to remove it? [y/N] "
        }
        PrOpen => {
          println("Warning: PR is still open.")
          "Are you sure you want to remove it? [y/N] "
        }
      }
      match self.prompter.confirm(prompt=confirm_msg) {
        Ok(true) => ()
        _ => { println("Cancelled."); return }
      }
      // Kill tmux window if exists
      if self.session.is_active() {
        match self.session.list_windows() {
          Ok(windows) =>
            if windows.contains(name) {
              match self.prompter.confirm(
                prompt="tmux window '\{name}' is open. Close it? [y/N] ",
              ) {
                Ok(true) => {
                  let _ = self.session.kill_window(name=name)
                  println("Closed tmux window: \{name}")
                }
                _ => ()
              }
            }
          Err(_) => ()
        }
      }
      // Remove worktree
      let git_dir = match self.repo_query.common_dir(workdir=t.workdir) {
        Ok(d) => d
        Err(e) => {
          println("Error: failed to get git repository info: \{e}")
          return
        }
      }
      match self.repo_mutator.remove_worktree(
        git_dir=git_dir,
        workdir=t.workdir,
      ) {
        Ok(_) => ()
        Err(e) => { println("Error removing worktree: \{e}"); return }
      }
      // Delete local branch
      if t.branch != "" {
        match self.repo_query.branch_exists(
          git_dir=git_dir,
          branch=t.branch,
        ) {
          Ok(true) => {
            match self.prompter.confirm(
              prompt="Delete local branch '\{t.branch}'? [y/N] ",
            ) {
              Ok(true) =>
                match self.repo_mutator.delete_branch(
                  git_dir=git_dir,
                  branch=t.branch,
                  force=false,
                ) {
                  Ok(_) => ()
                  Err(_) => {
                    println(
                      "Warning: branch '\{t.branch}' is not fully merged.",
                    )
                    match self.prompter.confirm(prompt="Force delete? [y/N] ") {
                      Ok(true) => {
                        let _ = self.repo_mutator.delete_branch(
                          git_dir=git_dir,
                          branch=t.branch,
                          force=true,
                        )
                      }
                      _ => ()
                    }
                  }
                }
              _ => ()
            }
          }
          _ => ()
        }
      }
      println("Task completed: \{name}")
    }
  }
}

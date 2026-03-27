///|
pub async fn cmd_done() -> Unit {
  let dir = @config.worktree_dir()
  let tasks = try { list_tasks() } catch { _ => [] }
  if tasks.is_empty() {
    println("No active tasks.")
    return
  }
  let selected = @services.fzf_select(tasks, prompt="Select Task to Complete> ")
  match selected {
    None => {
      println("Cancelled.")
      return
    }
    Some(task) => {
      let workdir = dir + "/" + task
      // Show status
      println("Task: \{task}")
      let info = get_task_status(workdir)
      let status_str = format_status(info.status)
      println(
        "\{status_str}\t\{info.branch}\t\{info.uncommitted} changed\t\{info.commits_ahead} commits\t\{info.pr_url}",
      )
      println("---")
      // Confirm based on status
      let confirmed = match info.status {
        Merged | NoChanges =>
          @services.confirm("Remove this worktree? [y/N] ")
        InProgress => {
          println("Warning: uncommitted or unmerged changes exist.")
          @services.confirm("Are you sure you want to remove it? [y/N] ")
        }
        PrOpen => {
          println("Warning: PR is still open.")
          @services.confirm("Are you sure you want to remove it? [y/N] ")
        }
      }
      if not(confirmed) {
        println("Cancelled.")
        return
      }
      // Kill tmux window if it exists
      if @services.is_in_tmux() {
        let windows = @services.tmux_list_windows()
        if windows.contains(task) {
          let close = @services.confirm(
            "tmux window '\{task}' is open. Close it? [y/N] ",
          )
          if close {
            @services.tmux_kill_window(task)
            println("Closed tmux window: \{task}")
          }
        }
      }
      // Remove worktree
      let git_dir = @services.git_common_dir(workdir)
      if git_dir == "" {
        println("Error: failed to get git repository info: \{workdir}")
        return
      }
      let (rm_status, rm_output) = @services.git_run(
        ["--git-dir=\{git_dir}", "worktree", "remove", workdir, "--force"],
      )
      if rm_status != 0 {
        println("Error removing worktree: \{rm_output}")
        return
      }
      // Delete local branch if it exists
      let (_, branch) = split_task_name(task)
      if branch != "" {
        let (list_status, list_output) = @services.git_run(
          ["--git-dir=\{git_dir}", "branch", "--list", branch],
        )
        if list_status == 0 && list_output.trim_end().to_string() != "" {
          let del = @services.confirm(
            "Delete local branch '\{branch}'? [y/N] ",
          )
          if del {
            let (del_status, _) = @services.git_run(
              ["--git-dir=\{git_dir}", "branch", "-d", branch],
            )
            if del_status != 0 {
              println("Warning: branch '\{branch}' is not fully merged.")
              let force = @services.confirm("Force delete? [y/N] ")
              if force {
                let _ = @services.git_run(
                  ["--git-dir=\{git_dir}", "branch", "-D", branch],
                )

              }
            }
          }
        }
      }
      println("Task completed: \{task}")
    }
  }
}

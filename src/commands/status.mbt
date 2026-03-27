///|
pub async fn get_task_status(workdir : String) -> @models.TaskInfo {
  let branch = @services.git_branch(workdir)
  let uncommitted = @services.git_uncommitted_count(workdir)
  let commits_ahead = @services.git_commits_ahead(workdir)
  let remote_url = @services.git_remote_url(workdir)
  let mut pr_state = ""
  let mut pr_url = ""
  if remote_url != "" {
    let slug = extract_repo_slug(remote_url)
    if slug != "" {
      let (state, url) = @services.gh_pr_status(slug, branch)
      pr_state = state
      pr_url = url
    }
  }
  let status : @models.TaskStatus = if pr_state == "MERGED" {
    Merged
  } else if pr_state == "OPEN" {
    PrOpen
  } else if uncommitted > 0 || commits_ahead > 0 {
    InProgress
  } else {
    NoChanges
  }
  @models.TaskInfo::{ status, branch, uncommitted, commits_ahead, pr_url }
}

///|
fn extract_repo_slug(remote_url : String) -> String {
  let mut url = remote_url
  // Remove .git suffix
  if url.has_suffix(".git") {
    url = url[:url.length() - 4].to_string()
  }
  // Try SSH format: git@github.com:user/repo
  if url.has_prefix("git@") {
    match url.find(":") {
      Some(idx) => return url[idx + 1:].to_string()
      None => ()
    }
  }
  // Try HTTPS format: https://github.com/user/repo
  match url.find("github.com/") {
    Some(idx) => url[idx + 11:].to_string()
    None => ""
  }
}

///|
fn format_status(status : @models.TaskStatus) -> String {
  match status {
    InProgress => "in-progress"
    PrOpen => "pr-open"
    Merged => "merged"
    NoChanges => "no-changes"
  }
}

///|
fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let buf = StringBuilder::new()
  buf.write_string(s)
  for i = len; i < width; i = i + 1 {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
fn print_table(rows : Array[Array[String]]) -> Unit {
  let col_count = rows[0].length()
  let widths = Array::make(col_count, 0)
  for row in rows {
    for i, cell in row {
      if cell.length() > widths[i] {
        widths[i] = cell.length()
      }
    }
  }
  for row in rows {
    let buf = StringBuilder::new()
    for i, cell in row {
      if i > 0 {
        buf.write_string("  ")
      }
      if i < col_count - 1 {
        buf.write_string(pad_right(cell, widths[i]))
      } else {
        buf.write_string(cell)
      }
    }
    println(buf.to_string())
  }
}

///|
pub async fn cmd_status(args : Array[String]) -> Unit {
  let show_all = args.length() > 0 && args[0] == "--all"
  let dir = @config.worktree_dir()
  if show_all {
    let tasks = try { list_tasks() } catch { _ => [] }
    let header = ["TASK", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
    let rows : Array[Array[String]] = [header]
    for task in tasks {
      let workdir = dir + "/" + task
      let info = get_task_status(workdir)
      rows.push(
        [
          task,
          format_status(info.status),
          info.branch,
          "\{info.uncommitted} changed",
          "\{info.commits_ahead} commits",
          info.pr_url,
        ],
      )
    }
    print_table(rows)
    return
  }
  // Interactive selection
  let tasks = try { list_tasks() } catch { _ => [] }
  if tasks.is_empty() {
    println("No active tasks.")
    return
  }
  let selected = @services.fzf_select(tasks, prompt="Select Task> ")
  match selected {
    None => println("Cancelled.")
    Some(task) => {
      let workdir = dir + "/" + task
      println("Task: \{task}")
      println("---")
      let info = get_task_status(workdir)
      println(
        "\{format_status(info.status)}\t\{info.branch}\t\{info.uncommitted} changed\t\{info.commits_ahead} commits\t\{info.pr_url}",
      )
    }
  }
}

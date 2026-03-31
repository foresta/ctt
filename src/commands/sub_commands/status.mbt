///|
/// Converts a TaskStatus enum value to its display string.
fn format_status(status : @ports.TaskStatus) -> String {
  match status {
    InProgress => "in-progress"
    PrOpen => "pr-open"
    Merged => "merged"
    NoChanges => "no-changes"
  }
}

///|
/// Builds a status row for a single task.
fn build_status_row(
  name : String,
  info : @ports.TaskInfo
) -> Array[String] {
  [
    name,
    format_status(info.status),
    info.branch,
    "\{info.uncommitted} changed",
    "\{info.commits_ahead} commits",
    info.pr_url,
  ]
}

///|
/// Shows git and PR status for tasks. Supports `--all` for a summary table or interactive single-task view.
pub(all) struct StatusCommand {
  repo : &@ports.RepositoryQuery
  tasks : &@task.TaskRepository
  params : Array[String]
}

///|
/// Returns a Table for --all, or a Select step for interactive single-task view.
impl @ports.Runnable for StatusCommand with run(self) {
  let show_all = self.params.length() > 0 && self.params[0] == "--all"
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if task_list.is_empty() {
    return @ports.Lines(["No active tasks."])
  }
  if show_all {
    let header = ["TASK", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
    let rows : Array[Array[String]] = [header]
    for t in task_list {
      match self.repo.get_task_status(workdir=t.workdir) {
        Ok(info) => rows.push(build_status_row(t.name, info))
        Err(e) => rows.push([t.name, "error", e, "", "", ""])
      }
    }
    return @ports.Table(rows)
  }
  let names = task_list.map(fn(t) { t.name })
  let repo = self.repo
  @ports.Select(
    message=[],
    items=names,
    prompt="Select Task> ",
    on_select=async fn(name) {
      let workdir = task_list
        .iter()
        .find_first(fn(t) { t.name == name })
        .map(fn(t) { t.workdir })
        .unwrap_or("")
      match repo.get_task_status(workdir=workdir) {
        Ok(info) => {
          let row = build_status_row(name, info)
          @ports.Lines(
            ["Task: " + name, "---", row.join("\t")],
          )
        }
        Err(e) => @ports.Lines(["Error: " + e])
      }
    },
  )
}

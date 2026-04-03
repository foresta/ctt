///|
/// Builds a Table with header and status rows for the given tasks.
async fn build_status_table(
  repo : &@ports.RepositoryQuery,
  tasks : Array[@task.Task]
) -> @ports.CommandResult {
  let header = ["TASK", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
  let rows : Array[Array[String]] = [header]
  for t in tasks {
    match repo.get_task_status(name=t.name, workdir=t.workdir) {
      Ok(info) => rows.push(info.to_row())
      Err(e) => rows.push([t.name, "error", e, "", "", ""])
    }
  }
  @ports.Table(rows)
}

///|
/// Shows git and PR status for tasks. `--all` shows all tasks, otherwise prompts for selection.
pub(all) struct StatusCommand {
  repo : &@ports.RepositoryQuery
  tasks : &@task.TaskRepository
  params : Array[String]
}

///|
/// Returns a Table for --all, or a Select step then Table for a single task.
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
    return build_status_table(self.repo, task_list)
  }
  let names = task_list.map(fn(t) { t.name })
  let repo = self.repo
  @ports.Select(
    items=names,
    prompt="Select Task> ",
    accept_empty=false,
    on_select=async fn(name) {
      match task_list.iter().find_first(fn(t) { t.name == name }) {
        Some(task) => build_status_table(repo, [task])
        None => @ports.Error("task not found: " + name)
      }
    },
  )
}

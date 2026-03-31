///|
/// Opens an existing task's worktree in the editor via interactive selection.
pub(all) struct OpenCommand {
  editor : &@ports.EditorLauncher
  tasks : &@task.TaskRepository
}

///|
/// Returns a Select step for the user to pick a task, then opens the editor.
impl @ports.Runnable for OpenCommand with run(self) {
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => return @ports.Error(e)
  }
  if task_list.is_empty() {
    return @ports.Lines(["No active tasks."])
  }
  let names = task_list.map(fn(t) { t.name })
  let editor = self.editor
  @ports.Select(
    message=[],
    items=names,
    prompt="Select Task> ",
    on_select=async fn(name) {
      let (repo_name, branch) = @task.parse_task_name(name)
      let workdir = task_list
        .iter()
        .find_first(fn(t) { t.name == name })
        .map(fn(t) { t.workdir })
        .unwrap_or("")
      let _ = editor.open(
        repo_name=repo_name,
        workdir=workdir,
        branch=branch,
        continue_session=true,
      )
      @ports.Lines(["Opened: " + name])
    },
  )
}

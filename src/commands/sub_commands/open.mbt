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
      match task_list.iter().find_first(fn(t) { t.name == name }) {
        Some(task) => {
          let _ = editor.open(
            repo_name=task.repo_name,
            workdir=task.workdir,
            branch=task.branch,
            continue_session=true,
          )
          @ports.Lines(["Opened: " + task.name])
        }
        None => @ports.Error("task not found: " + name)
      }
    },
  )
}

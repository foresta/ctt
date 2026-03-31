///|
/// Lists all active task names.
pub(all) struct LsCommand {
  tasks : &@task.TaskRepository
}

///|
/// Returns task names as Lines, or an error message if listing fails.
impl @ports.Runnable for LsCommand with run(self) {
  let tasks = match self.tasks.list() {
    Ok(t) => t
    Err(e) => raise @builtin.Failure(e)
  }
  if tasks.is_empty() {
    @ports.Lines(["No active tasks."])
  } else {
    @ports.Lines(tasks.map(fn(t) { t.name }))
  }
}

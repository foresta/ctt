///|
pub(all) struct OpenCommand {
  selector : &@ports.ItemSelector
  editor : &@ports.EditorLauncher
  tasks : &@task.TaskRepository
}

///|
impl Runnable for OpenCommand with run(self) {
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => { println("Error: \{e}"); return }
  }
  if task_list.is_empty() {
    println("No active tasks.")
    return
  }
  let names = task_list.map(fn(t) { t.name })
  let selected = match self.selector.select(items=names, prompt="Select Task> ") {
    Ok(s) => s
    Err(e) => { println("Error: \{e}"); return }
  }
  match selected {
    None => println("Cancelled.")
    Some(name) => {
      let (repo_name, branch) = @task.parse_task_name(name)
      let worktree_path = task_list
        .iter()
        .find_first(fn(t) { t.name == name })
        .map(fn(t) { t.workdir })
        .unwrap_or("")
      let _ = self.editor.open(
        repo_name=repo_name,
        workdir=worktree_path,
        branch=branch,
        continue_session=true,
      )
    }
  }
}

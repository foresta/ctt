///|
pub(all) struct OsTaskRepository {
  fs : &@ports.FileSystem
  workspace_dir : String
}

///|
impl @task.TaskRepository for OsTaskRepository with list(self) {
  let dir = @task.worktree_dir(self.workspace_dir)
  let entries = match self.fs.read_dir(path=dir) {
    Ok(e) => e
    Err(e) => return Err(e)
  }
  let tasks : Array[@task.Task] = []
  for entry in entries {
    let entry_path = dir + "/" + entry
    let is_dir = match self.fs.is_dir(path=entry_path) {
      Ok(d) => d
      Err(_) => false
    }
    if is_dir {
      let (repo_name, branch) = @task.parse_task_name(entry)
      tasks.push(
        @task.Task::{
          name: entry,
          repo_name,
          branch,
          workdir: entry_path,
        },
      )
    }
  }
  Ok(tasks)
}

///|
impl @task.TaskRepository for OsTaskRepository with find(self, name~) {
  let tasks = match self.list() {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  Ok(
    tasks.iter().find_first(fn(t) { t.name == name }),
  )
}

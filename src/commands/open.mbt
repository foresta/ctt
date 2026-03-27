///|
pub async fn cmd_open() -> Unit {
  let dir = @config.worktree_dir()
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
      // Extract repo_name and branch from "repo__branch" format
      let (repo_name, branch) = split_task_name(task)
      @services.open_editor(repo_name, workdir, branch, continue_session=true)
    }
  }
}

///|
fn split_task_name(name : String) -> (String, String) {
  match name.find("__") {
    Some(idx) => (name[:idx].to_string(), name[idx + 2:].to_string())
    None => (name, "")
  }
}

///|
pub(all) struct LsCommand {}

///|
impl Runnable for LsCommand with run(self) {
  let _ = self
  cmd_ls()
}

///|
pub fn cmd_ls() -> Unit raise {
  let tasks = list_tasks()
  if tasks.is_empty() {
    println("No active tasks.")
  } else {
    tasks.each(fn(t) { println(t) })
  }
}

///|
pub fn list_tasks() -> Array[String] raise {
  let dir = @config.worktree_dir()
  @fs.read_dir(dir)
    .filter(fn(entry) {
      let entry_path = @path.Path(dir).join(@path.Path(entry)).to_string()
      try { @fs.is_dir(entry_path) } catch { _ => false }
    })
}

///|
/// list_tasks() して空なら "No active tasks." を出力し None を返す。
/// タスクがあれば Some(tasks) を返す。
pub fn require_tasks() -> Array[String]? raise {
  let tasks = list_tasks()
  if tasks.is_empty() {
    println("No active tasks.")
    return None
  }
  Some(tasks)
}

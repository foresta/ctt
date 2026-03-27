///|
pub fn cmd_ls(tasks : Array[String]) -> Unit {
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

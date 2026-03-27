///|
pub fn cmd_ls() -> Unit raise {
  let dir = @config.worktree_dir()
  if not(@fs.path_exists(dir)) {
    println("Worktree directory not found: \{dir}")
    raise @builtin.Failure("worktree directory not found")
  }
  let entries = @fs.read_dir(dir)
  let mut found = false
  for entry in entries {
    let entry_path = @path.Path(dir).join(@path.Path(entry)).to_string()
    if @fs.is_dir(entry_path) {
      found = true
      println(entry)
    }
  }
  if not(found) {
    println("No active tasks.")
  }
}

///|
pub fn list_tasks() -> Array[String] raise {
  let dir = @config.worktree_dir()
  if not(@fs.path_exists(dir)) {
    return []
  }
  let entries = @fs.read_dir(dir)
  let tasks : Array[String] = []
  for entry in entries {
    let entry_path = @path.Path(dir).join(@path.Path(entry)).to_string()
    if @fs.is_dir(entry_path) {
      tasks.push(entry)
    }
  }
  tasks
}

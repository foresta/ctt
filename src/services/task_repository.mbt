///|
/// Adapter that implements the WorktreeRepository port using OS filesystem operations.
pub(all) struct OsWorktreeRepository {
  fs : &@ports.FileSystem
  workspace_dir : String
}

///|
/// List all worktrees by scanning worktree directories.
impl @ports.WorktreeRepository for OsWorktreeRepository with list(self) {
  let dir = @domain.worktree_dir(self.workspace_dir)
  let entries = match self.fs.read_dir(path=dir) {
    Ok(e) => e
    Err(e) => return Err(e)
  }
  let worktrees : Array[@ports.Worktree] = []
  for entry in entries {
    let entry_path = dir + "/" + entry
    let is_dir = match self.fs.is_dir(path=entry_path) {
      Ok(d) => d
      Err(_) => false
    }
    if is_dir {
      let (repo_name, branch) = @domain.parse_worktree_name(entry)
      worktrees.push(
        @ports.Worktree::{
          name: entry,
          repo_name,
          branch,
          workdir: entry_path,
        },
      )
    }
  }
  Ok(worktrees)
}

///|
/// Find a worktree by its exact name.
impl @ports.WorktreeRepository for OsWorktreeRepository with find(self, name~) {
  let worktrees = match self.list() {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  Ok(
    worktrees.iter().find_first(fn(t) { t.name == name }),
  )
}

///|
/// Parse a worktree name into a repo name and branch name, split by "__".
pub fn parse_worktree_name(name : String) -> (String, String) {
  match name.find("__") {
    Some(idx) => (name[:idx].to_string(), name[idx + 2:].to_string())
    None => (name, "")
  }
}

///|
/// Return the worktrees directory path under the given workspace directory.
pub fn worktree_dir(workspace_dir : String) -> String {
  workspace_dir + "/worktrees"
}

///|
/// Return the workdir path for a worktree given its repo name and branch.
pub fn worktree_path(workspace_dir : String, repo_name : String, branch : String) -> String {
  worktree_dir(workspace_dir) + "/" + repo_name + "__" + branch
}

///|
/// Service for worktree file management operations.
pub(all) struct WorktreeService {
  vcs : &@ports.VCS
  fs : &@ports.FileSystem
  config_dir : String
}

///|
/// Symlink git-ignored files from the source repository into a worktree.
/// Reads skip patterns from config_dir/.worktree-link-ignore.
/// Returns status messages for each linked file.
pub async fn WorktreeService::link_ignored_files(
  self : WorktreeService,
  repo_dir : String,
  workdir : String
) -> Array[String] {
  let output : Array[String] = []
  let ignore_file = self.config_dir + "/.worktree-link-ignore"
  let skip_patterns : Array[@glob.GlobPattern] = []
  if self.fs.path_exists(path=ignore_file) {
    match self.fs.read_file_to_string(path=ignore_file) {
      Ok(content) =>
        for part in content.split("\n") {
          match @glob.parse(part.to_string()) {
            Some(pat) => skip_patterns.push(pat)
            None => ()
          }
        }
      Err(_) => ()
    }
  }
  let ignored = match self.vcs.list_ignored_files(repo_dir=repo_dir) {
    Ok(files) => files
    Err(_) => return output
  }
  let mut linked = 0
  for path in ignored {
    let src = repo_dir + "/" + path
    let dst = workdir + "/" + path
    if not(self.fs.path_exists(path=src)) {
      continue
    }
    let skip = skip_patterns.fold(init=false, fn(acc, pattern) {
      if pattern.matches(path) { not(pattern.negated) } else { acc }
    })
    if skip || self.fs.path_exists(path=dst) {
      continue
    }
    let dst_dir = @path.dirname(dst)
    if not(self.fs.path_exists(path=dst_dir)) {
      let _ = self.fs.create_dir(path=dst_dir)
    }
    let is_dir = match self.fs.is_dir(path=src) {
      Ok(d) => d
      Err(_) => false
    }
    if is_dir {
      let _ = self.fs.create_dir(path=dst)
      match self.fs.read_dir(path=src) {
        Ok(children) =>
          for child in children {
            let child_dst = dst + "/" + child
            if not(self.fs.path_exists(path=child_dst)) {
              let child_src = src + "/" + child
              let _ = self.fs.create_symlink(src=child_src, dst=child_dst)
            }
          }
        Err(_) => ()
      }
    } else {
      let _ = self.fs.create_symlink(src=src, dst=dst)
    }
    linked = linked + 1
    output.push("Linked: " + path)
  }
  if linked > 0 {
    output.push("Linked " + linked.to_string() + " ignored file(s) into worktree.")
  }
  output
}

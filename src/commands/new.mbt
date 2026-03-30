///|
async fn select_repo() -> String {
  let workspace = @config.workspace_dir()
  // Find git repos using find command
  let (status, output) = @services.git_run(
    ["ls-remote", "--get-url"],  // dummy, we'll use find instead
  )
  let _ = status
  let _ = output
  let (find_status, find_output) = @process.collect_output_merged(
    "find",
    [workspace, "-maxdepth", "5", "-type", "d", "-name", ".git", "-prune"],
  )
  if find_status != 0 {
    println("Error: failed to search for repositories.")
    raise @builtin.Failure("find failed")
  }
  // Extract parent directories (remove /.git suffix)
  let repos : Array[String] = find_output
    .text()
    .trim_end()
    .to_string()
    .split("\n")
    .filter(fn(s) { s.length() > 0 })
    .map(fn(s) {
      let path = s.to_string()
      // Remove /.git suffix
      path[:path.length() - 5].to_string()
    })
    .collect()
  if repos.is_empty() {
    raise @builtin.Failure("no repositories found")
  }
  let selected = @services.fzf_select(repos, prompt="Select Repository> ")
  match selected {
    None => raise @builtin.Failure("cancelled")
    Some(repo) => repo
  }
}

///|
async fn select_branch(repo_dir : String) -> (String, Bool) {
  // Get local + remote branches
  let (_, local_output) = @services.git_run(
    ["branch", "--format=%(refname:short)"],
    cwd=repo_dir,
  )
  let (_, remote_output) = @services.git_run(
    ["branch", "-r", "--format=%(refname:short)"],
    cwd=repo_dir,
  )
  // Combine and deduplicate
  let branches : Array[String] = []
  let seen : Map[String, Bool] = {}
  // Add local branches
  for part in local_output.split("\n") {
    let b = part.to_string().trim_end().to_string()
    if b != "" && b != "HEAD" && not(seen.contains(b)) {
      branches.push(b)
      seen[b] = true
    }
  }
  // Add remote branches (strip origin/ prefix)
  for part in remote_output.split("\n") {
    let raw = part.to_string().trim_end().to_string()
    if raw == "" || raw == "HEAD" {
      continue
    }
    // Strip "origin/" prefix
    let b = match raw.find("/") {
      Some(idx) => raw[idx + 1:].to_string()
      None => raw
    }
    if b != "HEAD" && not(seen.contains(b)) {
      branches.push(b)
      seen[b] = true
    }
  }
  // Use fzf with --print-query to allow typing new branch name
  let (query, selected) = @services.fzf_select_with_query(
    branches,
    prompt="Select or Type Branch for Worktree> ",
  )
  match selected {
    Some(branch) => (branch, true) // existing branch
    None =>
      if query != "" {
        (query, false) // new branch name
      } else {
        raise @builtin.Failure("cancelled")
      }
  }
}

///|
async fn ask_branch_action() -> String {
  let options = ["Checkout this branch", "Create new branch from this branch"]
  let selected = @services.fzf_select(options, prompt="Select action> ")
  match selected {
    Some("Checkout this branch") => "checkout"
    Some("Create new branch from this branch") => "new_from_base"
    _ => raise @builtin.Failure("cancelled")
  }
}

///|
async fn input_new_branch_name() -> String {
  let name = @services.read_line("New branch name> ")
  if name == "" {
    raise @builtin.Failure("cancelled")
  }
  name
}

///|
async fn create_worktree(
  repo_dir : String,
  workdir : String,
  git_args : Array[String]
) -> (Bool, String) {
  // Returns (is_existing, workdir)
  if @fs.path_exists(workdir) {
    let reuse = @services.confirm(
      "Directory already exists: \{workdir} — Use existing worktree? [y/N] ",
    )
    if reuse {
      return (true, workdir)
    } else {
      raise @builtin.Failure("cancelled")
    }
  }
  let args : Array[String] = ["worktree", "add", workdir]
  for arg in git_args {
    args.push(arg)
  }
  let (status, output) = @services.git_run(args, cwd=repo_dir)
  if status != 0 {
    println("Error: \{output}")
    raise @builtin.Failure("git worktree add failed")
  }
  (false, workdir)
}

///|
pub(all) struct NewCommand {}

///|
impl Runnable for NewCommand with run(self) {
  let _ = self
  cmd_new()
}

///|
pub async fn cmd_new() -> Unit {
  let repo_dir = select_repo()
  let repo_name = match repo_dir.rev_find("/") {
    Some(idx) => repo_dir[idx + 1:].to_string()
    None => repo_dir
  }
  let (branch, is_existing) = select_branch(repo_dir)
  let mut git_args : Array[String] = []
  let mut target_branch = branch
  if is_existing {
    let action = ask_branch_action()
    if action == "new_from_base" {
      let new_name = input_new_branch_name()
      target_branch = new_name
      // Check if remote branch exists and fetch
      let (ls_status, _) = @services.git_run(
        ["ls-remote", "--exit-code", "origin", branch],
        cwd=repo_dir,
      )
      if ls_status == 0 {
        println("Fetching latest '\{branch}'...")
        let _ = @services.git_run(
          ["fetch", "origin", branch],
          cwd=repo_dir,
        )
        git_args = ["-b", target_branch, "origin/\{branch}"]
      } else {
        git_args = ["-b", target_branch, branch]
      }
    } else {
      git_args = [branch]
    }
  } else {
    git_args = ["-b", branch]
  }
  let worktree_dir = @config.worktree_dir()
  let workdir = "\{worktree_dir}/\{repo_name}__\{target_branch}"
  let (is_existing_wt, actual_workdir) = create_worktree(repo_dir, workdir, git_args)
  // Link ignored files
  link_ignored_files(repo_dir, actual_workdir)
  @services.open_editor(
    repo_name,
    actual_workdir,
    target_branch,
    continue_session=is_existing_wt,
  )
}

///|
async fn link_ignored_files(repo_dir : String, workdir : String) -> Unit {
  let config_dir = @config.config_dir()
  let ignore_file = config_dir + "/.worktree-link-ignore"
  // Load skip patterns
  let skip_patterns : Array[String] = []
  if @fs.path_exists(ignore_file) {
    try {
      let content = @fs.read_file_to_string(ignore_file)
      for part in content.split("\n") {
        let line = part.to_string().trim_end().to_string()
        if line == "" || line.has_prefix("#") {
          continue
        }
        skip_patterns.push(line)
      }
    } catch {
      _ => ()
    }
  }
  // Get ignored files from git
  let (status, output) = @services.git_run(
    ["ls-files", "--others", "--ignored", "--exclude-standard", "--directory"],
    cwd=repo_dir,
  )
  if status != 0 || output == "" {
    return
  }
  let mut linked = 0
  for part in output.split("\n") {
    let mut path = part.to_string().trim_end().to_string()
    if path == "" {
      continue
    }
    // Remove trailing slash
    if path.has_suffix("/") {
      path = path[:path.length() - 1].to_string()
    }
    let src = repo_dir + "/" + path
    let dst = workdir + "/" + path
    if not(@fs.path_exists(src)) {
      continue
    }
    // Check skip patterns
    let mut skip = false
    for pattern in skip_patterns {
      if path == pattern {
        skip = true
        break
      }
    }
    if skip {
      continue
    }
    // Skip if already exists
    if @fs.path_exists(dst) {
      continue
    }
    println("Linking... :\{src}")
    // Create parent directory
    let dst_dir = match dst.rev_find("/") {
      Some(idx) => dst[:idx].to_string()
      None => dst
    }
    if not(@fs.path_exists(dst_dir)) {
      try { @fs.create_dir(dst_dir) } catch { _ => () }
    }
    // Create symlink using ln -s
    let is_dir = try { @fs.is_dir(src) } catch { _ => false }
    if is_dir {
      // For directories: create dir and link children
      try { @fs.create_dir(dst) } catch { _ => () }
      try {
        let children = @fs.read_dir(src)
        for child in children {
          let child_dst = dst + "/" + child
          if not(@fs.path_exists(child_dst)) {
            let child_src = src + "/" + child
            let _ = @services.git_run(
              ["-c", "ln -s '\{child_src}' '\{child_dst}'"],
            )
            // Use sh for symlink since no direct API
            let _ = @process.run(
              "ln",
              ["-s", child_src, child_dst],
            )

          }
        }
      } catch {
        _ => ()
      }
    } else {
      let _ = @process.run("ln", ["-s", src, dst])

    }
    linked = linked + 1
    println("Linked: \{path}")
  }
  if linked > 0 {
    println("Linked \{linked} ignored file(s) into worktree.")
  }
}

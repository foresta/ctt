///|
/// Adapter that implements RepositoryQuery and RepositoryMutator ports using the git CLI.
pub(all) struct GitCli {}

///|
/// Run a git command and return (exit_status, trimmed_output).
async fn git_run(args : Array[String], cwd~ : String = "") -> (Int, String) {
  let (status, output) = run_and_collect_merged("git", args, cwd=cwd)
  (status, output.trim_end().to_string())
}

///|
/// Extract the owner/repo slug from a git remote URL.
fn extract_repo_slug_impl(remote_url : String) -> String {
  let mut url = remote_url
  if url.has_suffix(".git") {
    url = url[:url.length() - 4].to_string()
  }
  if url.has_prefix("git@") {
    match url.find(":") {
      Some(idx) => return url[idx + 1:].to_string()
      None => ()
    }
  }
  match url.find("github.com/") {
    Some(idx) => url[idx + 11:].to_string()
    None => ""
  }
}

///|
/// Gather branch, uncommitted changes, commits ahead, and PR status for a worktree.
impl @ports.RepositoryQuery for GitCli with get_task_status(self, name~, workdir~) {
  let _ = self
  let (_, branch) = git_run(["-C", workdir, "rev-parse", "--abbrev-ref", "HEAD"])
  let (_, uc_output) = git_run(["-C", workdir, "status", "--porcelain"])
  let uncommitted = if uc_output == "" {
    0
  } else {
    uc_output.split("\n").fold(init=0, fn(acc, _) { acc + 1 })
  }
  let (ca_status, ca_output) = git_run(
    ["-C", workdir, "log", "--oneline", "origin/main..HEAD"],
  )
  let commits_ahead = if ca_status != 0 || ca_output == "" {
    0
  } else {
    ca_output.split("\n").fold(init=0, fn(acc, _) { acc + 1 })
  }
  let (ru_status, remote_url) = git_run(
    ["-C", workdir, "remote", "get-url", "origin"],
  )
  let mut pr_state = ""
  let mut pr_url = ""
  if ru_status == 0 && remote_url != "" {
    let slug = extract_repo_slug_impl(remote_url)
    if slug != "" {
      let gh = GhCli::{}
      match gh.get_status(repo_slug=slug, branch=branch) {
        Ok(pr) => {
          pr_state = pr.state
          pr_url = pr.url
        }
        Err(_) => ()
      }
    }
  }
  let status : @ports.TaskStatus = if pr_state == "MERGED" {
    Merged
  } else if pr_state == "OPEN" {
    PrOpen
  } else if uncommitted > 0 || commits_ahead > 0 {
    InProgress
  } else {
    NoChanges
  }
  Ok(@ports.TaskInfo::{ name, status, branch, uncommitted, commits_ahead, pr_url })
}

///|
/// List local and remote branches for the given repository directory.
impl @ports.RepositoryQuery for GitCli with list_branches(self, repo_dir~) {
  let _ = self
  let (_, local_output) = git_run(
    ["branch", "--format=%(refname:short)"],
    cwd=repo_dir,
  )
  let (_, remote_output) = git_run(
    ["branch", "-r", "--format=%(refname:short)"],
    cwd=repo_dir,
  )
  let local_branches : Array[String] = local_output
    .split("\n")
    .map(fn(s) { s.to_string() })
    .filter(fn(s) { s != "" && s != "HEAD" })
    .collect()
  let seen : Map[String, Bool] = {}
  for b in local_branches {
    seen[b] = true
  }
  let remote_branches : Array[String] = remote_output
    .split("\n")
    .map(fn(s) {
      let raw = s.to_string()
      match raw.find("/") {
        Some(idx) => raw[idx + 1:].to_string()
        None => raw
      }
    })
    .filter(fn(s) { s != "" && s != "HEAD" && not(seen.contains(s)) })
    .collect()
  Ok(@ports.BranchList::{ local_branches, remote_branches })
}

///|
/// Return the git common directory shared across worktrees.
impl @ports.RepositoryQuery for GitCli with common_dir(self, workdir~) {
  let _ = self
  let (status, output) = git_run(
    ["-C", workdir, "rev-parse", "--git-common-dir"],
  )
  if status != 0 || output == "" {
    Err("failed to get git common dir")
  } else {
    Ok(output)
  }
}

///|
/// Check whether a branch exists in the given git directory.
impl @ports.RepositoryQuery for GitCli with branch_exists(self, git_dir~, branch~) {
  let _ = self
  let (status, output) = git_run(
    ["--git-dir=" + git_dir, "branch", "--list", branch],
  )
  Ok(status == 0 && output.trim_end().to_string() != "")
}

///|
/// List files and directories ignored by .gitignore.
impl @ports.RepositoryQuery for GitCli with list_ignored_files(self, repo_dir~) {
  let _ = self
  let (status, output) = git_run(
    ["ls-files", "--others", "--ignored", "--exclude-standard", "--directory"],
    cwd=repo_dir,
  )
  if status != 0 || output == "" {
    return Ok([])
  }
  let files : Array[String] = output
    .split("\n")
    .map(fn(s) {
      let path = s.to_string()
      if path.has_suffix("/") {
        path[:path.length() - 1].to_string()
      } else {
        path
      }
    })
    .filter(fn(s) { s != "" })
    .collect()
  Ok(files)
}

///|
/// Create a new worktree with a new branch, optionally based on a given branch.
impl @ports.RepositoryMutator for GitCli with create_branch_worktree(
  self, repo_dir~, workdir~, branch~, base_branch~
) {
  let _ = self
  let args : Array[String] = match base_branch {
    Some(base) => {
      let (ls_status, _) = git_run(
        ["ls-remote", "--exit-code", "origin", base],
        cwd=repo_dir,
      )
      if ls_status == 0 {
        let _ = git_run(["fetch", "origin", base], cwd=repo_dir)
        ["worktree", "add", workdir, "-b", branch, "origin/" + base]
      } else {
        ["worktree", "add", workdir, "-b", branch, base]
      }
    }
    None => ["worktree", "add", workdir, "-b", branch]
  }
  let (status, output) = git_run(args, cwd=repo_dir)
  if status != 0 {
    return Err("git worktree add failed: " + output)
  }
  Ok(())
}

///|
/// Create a worktree that checks out an existing branch.
impl @ports.RepositoryMutator for GitCli with checkout_worktree(
  self, repo_dir~, workdir~, branch~
) {
  let _ = self
  let (status, output) = git_run(
    ["worktree", "add", workdir, branch],
    cwd=repo_dir,
  )
  if status != 0 {
    return Err("git worktree add failed: " + output)
  }
  Ok(())
}

///|
/// Force-remove a worktree by its working directory path.
impl @ports.RepositoryMutator for GitCli with remove_worktree(
  self, git_dir~, workdir~
) {
  let _ = self
  let (status, output) = git_run(
    ["--git-dir=" + git_dir, "worktree", "remove", workdir, "--force"],
  )
  if status != 0 {
    return Err("git worktree remove failed: " + output)
  }
  Ok(())
}

///|
/// Delete a branch, optionally with force.
impl @ports.RepositoryMutator for GitCli with delete_branch(
  self, git_dir~, branch~, force~
) {
  let _ = self
  let flag = if force { "-D" } else { "-d" }
  let (status, output) = git_run(
    ["--git-dir=" + git_dir, "branch", flag, branch],
  )
  if status != 0 {
    return Err("branch delete failed: " + output)
  }
  Ok(())
}

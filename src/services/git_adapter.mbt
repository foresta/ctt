///|
pub(all) struct GitCli {}

///|
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
impl @ports.RepositoryQuery for GitCli with get_task_status(self, workdir~) {
  let _ = self
  let branch = git_branch(workdir)
  let uncommitted = git_uncommitted_count(workdir)
  let commits_ahead = git_commits_ahead(workdir)
  let remote_url = git_remote_url(workdir)
  let mut pr_state = ""
  let mut pr_url = ""
  if remote_url != "" {
    let slug = extract_repo_slug_impl(remote_url)
    if slug != "" {
      let (state, url) = gh_pr_status(slug, branch)
      pr_state = state
      pr_url = url
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
  Ok(@ports.TaskInfo::{ status, branch, uncommitted, commits_ahead, pr_url })
}

///|
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
impl @ports.RepositoryQuery for GitCli with common_dir(self, workdir~) {
  let _ = self
  let result = git_common_dir(workdir)
  if result == "" {
    Err("failed to get git common dir")
  } else {
    Ok(result)
  }
}

///|
impl @ports.RepositoryQuery for GitCli with branch_exists(self, git_dir~, branch~) {
  let _ = self
  let (status, output) = git_run(
    ["--git-dir=" + git_dir, "branch", "--list", branch],
  )
  Ok(status == 0 && output.trim_end().to_string() != "")
}

///|
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
impl @ports.RepositoryMutator for GitCli with create_branch_worktree(
  self,
  repo_dir~,
  workdir~,
  branch~,
  base_branch~
) {
  let _ = self
  let args : Array[String] = match base_branch {
    Some(base) => {
      // Check if remote branch exists and fetch
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
impl @ports.RepositoryMutator for GitCli with checkout_worktree(
  self,
  repo_dir~,
  workdir~,
  branch~
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
impl @ports.RepositoryMutator for GitCli with remove_worktree(
  self,
  git_dir~,
  workdir~
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
impl @ports.RepositoryMutator for GitCli with delete_branch(
  self,
  git_dir~,
  branch~,
  force~
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

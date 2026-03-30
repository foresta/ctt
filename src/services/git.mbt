///|
/// Run a git command with the given arguments and return the exit status and merged output.
pub async fn git_run(args : Array[String], cwd~ : String = "") -> (Int, String) {
  let (status, output) = if cwd == "" {
    @process.collect_output_merged("git", args)
  } else {
    @process.collect_output_merged("git", args, cwd=cwd)
  }
  (status, output.text().trim_end().to_string())
}

///|
/// Return the current branch name for the given working directory.
pub async fn git_branch(workdir : String) -> String {
  let (_, output) = git_run(["-C", workdir, "rev-parse", "--abbrev-ref", "HEAD"])
  output
}

///|
/// Count the number of uncommitted changes (from `git status --porcelain`).
pub async fn git_uncommitted_count(workdir : String) -> Int {
  let (_, output) = git_run(["-C", workdir, "status", "--porcelain"])
  if output == "" {
    0
  } else {
    output.split("\n").fold(init=0, fn(acc, _) { acc + 1 })
  }
}

///|
/// Count commits ahead of origin/main for the given working directory.
pub async fn git_commits_ahead(workdir : String) -> Int {
  let (status, output) = git_run(
    ["-C", workdir, "log", "--oneline", "origin/main..HEAD"],
  )
  if status != 0 || output == "" {
    0
  } else {
    output.split("\n").fold(init=0, fn(acc, _) { acc + 1 })
  }
}

///|
/// Return the remote origin URL for the given working directory.
pub async fn git_remote_url(workdir : String) -> String {
  let (status, output) = git_run(
    ["-C", workdir, "remote", "get-url", "origin"],
  )
  if status != 0 { "" } else { output }
}

///|
/// Return the git common directory (shared across worktrees) for the given path.
pub async fn git_common_dir(workdir : String) -> String {
  let (status, output) = git_run(
    ["-C", workdir, "rev-parse", "--git-common-dir"],
  )
  if status != 0 { "" } else { output }
}

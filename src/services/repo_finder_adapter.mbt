///|
pub(all) struct FindCommandFinder {}

///|
impl @ports.RepositoryFinder for FindCommandFinder with find_git_repos(self, workspace~, max_depth~) {
  let _ = self
  let (status, output) = @process.collect_output_merged(
    "find",
    [workspace, "-maxdepth", max_depth.to_string(), "-type", "d", "-name", ".git", "-prune"],
  )
  if status != 0 {
    return Err("find failed")
  }
  let repos : Array[String] = output
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
  Ok(repos)
}

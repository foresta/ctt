///|
/// Service for discovering VCS repositories in the filesystem.
pub(all) struct DiscoveryService {
  vcs : &@ports.VCS
  fs : &@ports.FileSystem
}

///|
/// Find VCS repositories by searching for repository marker directories.
pub async fn DiscoveryService::find_repos(
  self : DiscoveryService,
  workspace~ : String,
  max_depth~ : Int
) -> Result[Array[String], String] {
  let marker = self.vcs.repo_marker_name()
  let marker_len = marker.length() + 1 // +1 for leading /
  let dirs = match self.fs.find_dirs(path=workspace, name=marker, max_depth=max_depth) {
    Ok(d) => d
    Err(e) => return Err(e)
  }
  let repos : Array[String] = dirs
    .iter()
    .filter(fn(s) { s.length() > marker_len })
    .map(fn(s) {
      // Remove /marker suffix
      s[:s.length() - marker_len].to_owned()
    })
    .collect()
  Ok(repos)
}

///|
/// Pick the repository named by `query` out of discovered `repos`.
/// An absolute path must match a discovered repository exactly; a bare name
/// matches on the directory name and must be unique.
pub fn resolve_repo(repos : Array[String], query : String) -> Result[String, String] {
  if query.has_prefix("/") {
    let path = if query.length() > 1 && query.has_suffix("/") {
      query[:query.length() - 1].to_owned()
    } else {
      query
    }
    if repos.contains(path) {
      Ok(path)
    } else {
      Err("repository not found under workspace: " + path)
    }
  } else {
    let matches = repos.filter(fn(r) { @path.basename(r) == query })
    match matches.length() {
      0 => Err("repository '\{query}' not found under workspace")
      1 => Ok(matches[0])
      _ =>
        Err(
          "repository '\{query}' is ambiguous; pass a path: " +
          matches.join(", "),
        )
    }
  }
}

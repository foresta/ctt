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
      s[:s.length() - marker_len].to_string()
    })
    .collect()
  Ok(repos)
}

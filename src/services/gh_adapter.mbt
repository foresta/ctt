///|
/// Adapter that implements the PullRequestService port using the gh CLI.
pub(all) struct GhCli {}

///|
/// Get the PR state and URL for a branch in the given repository.
impl @ports.PullRequestService for GhCli with get_status(self, repo_slug~, branch~) {
  let _ = self
  let (state, url) = gh_pr_status(repo_slug, branch)
  Ok(@ports.PrStatus::{ state, url })
}

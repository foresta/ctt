///|
pub(all) struct GhCli {}

///|
impl @ports.PullRequestService for GhCli with get_status(self, repo_slug~, branch~) {
  let _ = self
  let (state, url) = gh_pr_status(repo_slug, branch)
  Ok(@ports.PrStatus::{ state, url })
}

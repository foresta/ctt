///|
/// State and URL of a pull request associated with a branch.
pub(all) struct PrStatus {
  state : String
  url : String
}

///|
/// Port for querying pull request information from a hosting service.
pub(open) trait PullRequestService {
  async get_status(Self, repo_slug~ : String, branch~ : String) -> Result[PrStatus, String]
}

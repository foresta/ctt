///|
pub(all) struct PrStatus {
  state : String
  url : String
}

///|
pub(open) trait PullRequestService {
  async get_status(Self, repo_slug~ : String, branch~ : String) -> Result[PrStatus, String]
}

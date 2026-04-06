///|
/// Adapter that implements the PullRequestService port using the gh CLI.
pub(all) struct GhCli {}

///|
/// Get the PR state and URL for a branch in the given repository.
impl @ports.PullRequestService for GhCli with get_status(self, repo_slug~, branch~) {
  let _ = self
  let (status, output) = @process.collect_output_merged(
    "gh",
    [
      "pr", "list", "--repo", repo_slug, "--head", branch,
      "--state", "all", "--json", "state,url", "--limit", "1",
    ],
  )
  if status != 0 {
    return Ok(@ports.PrStatus::{ state: "", url: "" })
  }
  let text = decode_process_output(output.binary()).trim_end().to_string()
  if text == "" || text == "[]" {
    return Ok(@ports.PrStatus::{ state: "", url: "" })
  }
  let state = extract_json_string(text, "state")
  let url = extract_json_string(text, "url")
  Ok(@ports.PrStatus::{ state, url })
}

///|
/// Extract a string value for the given key from a simple JSON string.
fn extract_json_string(json : String, key : String) -> String {
  let pattern = "\"\{key}\":\""
  match json.find(pattern) {
    None => ""
    Some(start) => {
      let value_start = start + pattern.length()
      let rest = json.to_string()[value_start:].to_string()
      match rest.find("\"") {
        None => ""
        Some(end) => rest.to_string()[:end].to_string()
      }
    }
  }
}

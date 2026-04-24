///|
/// Internal helper that queries pull request status using the gh CLI.
pub(all) struct GhCli {}

///|
/// PR state and URL information.
pub(all) struct PrStatus {
  state : String
  url : String
}

///|
/// Get the PR state and URL for a branch in the given repository.
async fn GhCli::get_status(
  self : GhCli,
  repo_slug~ : String,
  branch~ : String
) -> Result[PrStatus, String] {
  let _ = self
  let (status, output) = @proc.exec_cmd(
    "gh",
    [
      "pr", "list", "--repo", repo_slug, "--head", branch,
      "--state", "all", "--json", "state,url", "--limit", "1",
    ],
  )
  if status != 0 {
    return Ok(PrStatus::{ state: "", url: "" })
  }
  let text = output.trim_end().to_string()
  if text == "" || text == "[]" {
    return Ok(PrStatus::{ state: "", url: "" })
  }
  let state = extract_json_string(text, "state")
  let url = extract_json_string(text, "url")
  Ok(PrStatus::{ state, url })
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

///|
pub async fn gh_pr_status(
  repo_slug : String,
  branch : String
) -> (String, String) {
  let (status, output) = @process.collect_output_merged(
    "gh",
    [
      "pr", "list", "--repo", repo_slug, "--head", branch,
      "--state", "all", "--json", "state,url", "--limit", "1",
    ],
  )
  if status != 0 {
    return ("", "")
  }
  let text = output.text().trim_end().to_string()
  if text == "" || text == "[]" {
    return ("", "")
  }
  let state = extract_json_string(text, "state")
  let url = extract_json_string(text, "url")
  (state, url)
}

///|
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

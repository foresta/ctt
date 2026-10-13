///|
/// Pure helpers for driving the herdr CLI: argv construction and JSON response
/// parsing. No process execution happens here so everything is unit-testable.

///|
/// IDs returned by `herdr workspace create`.
pub(all) struct CreatedWorkspace {
  workspace_id : String
  tab_id : String
  root_pane_id : String
} derive(Eq, Debug)

///|
pub extend CreatedWorkspace with Eq::{equal, not_equal}

///|
pub extend CreatedWorkspace with @debug.Debug::{to_repr}

///|
/// One entry of `herdr workspace list`. `label` is empty when herdr omits it.
pub(all) struct WorkspaceEntry {
  workspace_id : String
  label : String
} derive(Eq, Debug)

///|
pub extend WorkspaceEntry with Eq::{equal, not_equal}

///|
pub extend WorkspaceEntry with @debug.Debug::{to_repr}

// --- labels and commands ---

///|
/// Workspace label for a task: `<repo_name>__<branch>` (same shape as the worktree dir name).
pub fn label(repo_name : String, branch : String) -> String {
  "\{repo_name}__\{branch}"
}

///|
/// Shell line for the agent pane: `resume` when the worktree already existed.
pub fn select_agent_command(
  new_command~ : String,
  resume_command~ : String,
  continue_session~ : Bool
) -> String {
  if continue_session {
    resume_command
  } else {
    new_command
  }
}

// --- argv builders (arguments after the `herdr` binary) ---

///|
pub fn workspace_create_args(cwd~ : String, label~ : String) -> Array[String] {
  ["workspace", "create", "--cwd", cwd, "--label", label, "--no-focus"]
}

///|
pub fn workspace_list_args() -> Array[String] {
  ["workspace", "list"]
}

///|
pub fn workspace_focus_args(workspace_id : String) -> Array[String] {
  ["workspace", "focus", workspace_id]
}

///|
pub fn workspace_close_args(workspace_id : String) -> Array[String] {
  ["workspace", "close", workspace_id]
}

///|
/// Split `pane_id` to the right; the new pane is a plain shell in `cwd`.
pub fn pane_split_args(pane_id~ : String, cwd~ : String) -> Array[String] {
  ["pane", "split", pane_id, "--direction", "right", "--cwd", cwd, "--no-focus"]
}

///|
/// Run `command` in `pane_id`. The command is passed as one argv element; herdr
/// sends it to the pane's shell followed by Enter.
pub fn pane_run_args(pane_id~ : String, command~ : String) -> Array[String] {
  ["pane", "run", pane_id, command]
}

// --- response parsing ---

///|
fn parse_json(text : String) -> Result[Json, String] {
  Ok(@json.parse(text)) catch {
    e => Err("herdr: invalid JSON response: \{e}")
  }
}

///|
/// Parse the response of `herdr workspace create`.
pub fn parse_workspace_create(
  text : String,
) -> Result[CreatedWorkspace, String] {
  let json = match parse_json(text) {
    Ok(j) => j
    Err(e) => return Err(e)
  }
  guard json
    is {
      "result": {
        "workspace": { "workspace_id": String(workspace_id), .. },
        "tab": { "tab_id": String(tab_id), .. },
        "root_pane": { "pane_id": String(root_pane_id), .. },
        ..
      },
      ..
    } else {
    return Err(
      "herdr: unexpected `workspace create` response: " +
      text.trim_end().to_owned(),
    )
  }
  Ok({ workspace_id, tab_id, root_pane_id, })
}

///|
/// Parse the response of `herdr pane split`; returns the new pane id.
pub fn parse_pane_split(text : String) -> Result[String, String] {
  let json = match parse_json(text) {
    Ok(j) => j
    Err(e) => return Err(e)
  }
  guard json
    is { "result": { "pane": { "pane_id": String(pane_id), .. }, .. }, .. } else {
    return Err(
      "herdr: unexpected `pane split` response: " + text.trim_end().to_owned(),
    )
  }
  Ok(pane_id)
}

///|
/// Parse the response of `herdr workspace list`. Entries without a string
/// `workspace_id` are skipped; a missing `label` becomes "".
pub fn parse_workspace_list(
  text : String,
) -> Result[Array[WorkspaceEntry], String] {
  let json = match parse_json(text) {
    Ok(j) => j
    Err(e) => return Err(e)
  }
  guard json is { "result": { "workspaces": Array(items), .. }, .. } else {
    return Err(
      "herdr: unexpected `workspace list` response: " +
      text.trim_end().to_owned(),
    )
  }
  let entries : Array[WorkspaceEntry] = []
  for item in items {
    guard item is { "workspace_id": String(workspace_id), .. } else { continue }
    let label = match item {
      { "label": String(l), .. } => l
      _ => ""
    }
    entries.push({ workspace_id, label, })
  }
  Ok(entries)
}

///|
/// Find the workspace whose label exactly equals `label`.
pub fn find_workspace_id(
  entries : Array[WorkspaceEntry],
  label~ : String,
) -> String? {
  match entries.iter().find_first(fn(e) { e.label == label }) {
    Some(e) => Some(e.workspace_id)
    None => None
  }
}

///|
/// Extract a human-readable message from a failed herdr invocation.
/// Tries the JSON shapes `{"error": "..."}`, `{"error": {"message": "..."}}` and
/// `{"message": "..."}` on stderr, then falls back to raw stderr, raw stdout,
/// and finally "unknown error".
pub fn parse_error_message(stderr : String, stdout : String) -> String {
  let err = stderr.trim().to_owned()
  if err != "" {
    match parse_json(err) {
      Ok({ "error": String(m), .. }) => return m
      Ok({ "error": { "message": String(m), .. }, .. }) => return m
      Ok({ "message": String(m), .. }) => return m
      _ => return err
    }
  }
  let out = stdout.trim().to_owned()
  if out != "" {
    return out
  }
  "unknown error"
}

///|
// --- label / command ---

test "label joins repo and branch with __" {
  assert_eq(@herdr.label("ctt", "feat/x"), "ctt__feat/x")
}

///|
test "select_agent_command picks resume only for an existing worktree" {
  let resumed = "claude --continue || claude"
  assert_eq(
    @herdr.select_agent_command(
      new_command="claude", resume_command=resumed, continue_session=false,
    ),
    "claude",
  )
  assert_eq(
    @herdr.select_agent_command(
      new_command="claude", resume_command=resumed, continue_session=true,
    ),
    resumed,
  )
}

///|
// --- argv builders ---

test "workspace_create_args" {
  assert_eq(@herdr.workspace_create_args(cwd="/w/t", label="r__b"), [
    "workspace", "create", "--cwd", "/w/t", "--label", "r__b", "--no-focus",
  ])
}

///|
test "workspace_list_args" {
  assert_eq(@herdr.workspace_list_args(), ["workspace", "list"])
}

///|
test "workspace_focus_args / workspace_close_args" {
  assert_eq(@herdr.workspace_focus_args("w3"), ["workspace", "focus", "w3"])
  assert_eq(@herdr.workspace_close_args("w3"), ["workspace", "close", "w3"])
}

///|
test "pane_split_args splits right without focus" {
  assert_eq(@herdr.pane_split_args(pane_id="w3:p1", cwd="/w/t"), [
    "pane", "split", "w3:p1", "--direction", "right", "--cwd", "/w/t", "--no-focus",
  ])
}

///|
test "pane_run_args keeps the command as a single argv element" {
  assert_eq(
    @herdr.pane_run_args(pane_id="w3:p1", command="claude --continue"),
    ["pane", "run", "w3:p1", "claude --continue"],
  )
}

///|
// --- parse_workspace_create ---

test "parse_workspace_create: valid response" {
  let text =
    #|{"id":"cli:workspace:create","result":{"type":"workspace_created","workspace":{"workspace_id":"w3","label":"r__b"},"tab":{"tab_id":"w3:t1"},"root_pane":{"pane_id":"w3:p1"}}}
  let created = @herdr.parse_workspace_create(text).unwrap()
  assert_eq(created, @herdr.CreatedWorkspace::{
    workspace_id: "w3",
    tab_id: "w3:t1",
    root_pane_id: "w3:p1",
  })
}

///|
test "parse_workspace_create: missing root_pane is an error" {
  let text =
    #|{"result":{"workspace":{"workspace_id":"w3"},"tab":{"tab_id":"w3:t1"}}}
  match @herdr.parse_workspace_create(text) {
    Err(e) => assert_true(e.contains("workspace create"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "parse_workspace_create: invalid JSON is an error" {
  match @herdr.parse_workspace_create("not json") {
    Err(e) => assert_true(e.contains("invalid JSON"))
    Ok(_) => fail("expected Err")
  }
}

///|
// --- parse_pane_split ---

test "parse_pane_split: valid response" {
  let text =
    #|{"result":{"type":"pane_split","pane":{"pane_id":"w3:p2","tab_id":"w3:t1"}}}
  assert_eq(@herdr.parse_pane_split(text), Ok("w3:p2"))
}

///|
test "parse_pane_split: missing pane is an error" {
  match @herdr.parse_pane_split("{\"result\":{}}") {
    Err(e) => assert_true(e.contains("pane split"))
    Ok(_) => fail("expected Err")
  }
}

///|
// --- parse_workspace_list / find_workspace_id ---

test "parse_workspace_list: empty list" {
  let text =
    #|{"result":{"type":"workspace_list","workspaces":[]}}
  assert_eq(@herdr.parse_workspace_list(text), Ok([]))
}

///|
test "parse_workspace_list: entries, missing label becomes empty" {
  let text =
    #|{"result":{"workspaces":[{"workspace_id":"w1","label":"a__b","focused":true},{"workspace_id":"w2"}]}}
  assert_eq(
    @herdr.parse_workspace_list(text),
    Ok([
      @herdr.WorkspaceEntry::{ workspace_id: "w1", label: "a__b", },
      @herdr.WorkspaceEntry::{ workspace_id: "w2", label: "", },
    ]),
  )
}

///|
test "parse_workspace_list: invalid JSON is an error" {
  assert_true(@herdr.parse_workspace_list("") is Err(_))
}

///|
test "find_workspace_id: exact match only" {
  let entries = [
    @herdr.WorkspaceEntry::{ workspace_id: "w1", label: "repo__main", },
    @herdr.WorkspaceEntry::{ workspace_id: "w2", label: "repo__main2", },
  ]
  assert_eq(@herdr.find_workspace_id(entries, label="repo__main2"), Some("w2"))
  assert_eq(@herdr.find_workspace_id(entries, label="repo__main"), Some("w1"))
  assert_eq(@herdr.find_workspace_id(entries, label="repo__dev"), None)
}

///|
// --- parse_error_message ---

test "parse_error_message: string error" {
  assert_eq(@herdr.parse_error_message("{\"error\":\"boom\"}", ""), "boom")
}

///|
test "parse_error_message: nested message" {
  assert_eq(
    @herdr.parse_error_message(
      "{\"error\":{\"code\":\"x\",\"message\":\"nested\"}}", "",
    ),
    "nested",
  )
}

///|
test "parse_error_message: raw text fallback and stdout fallback" {
  assert_eq(
    @herdr.parse_error_message("connection refused\n", ""),
    "connection refused",
  )
  assert_eq(@herdr.parse_error_message("", "  out  "), "out")
}

///|
test "parse_error_message: both empty" {
  assert_eq(@herdr.parse_error_message("", ""), "unknown error")
}

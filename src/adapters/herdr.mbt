///|
/// Adapter that implements WorkspaceManager with the herdr CLI.
/// Each task gets one workspace labelled `<repo_name>__<branch>` with a single
/// tab: the left pane runs the agent command (or the resume command when the
/// worktree already existed), the right pane is a shell in the worktree.
pub(all) struct HerdrWorkspace {
  agent_command : String
  agent_resume_command : String
}

///|
/// Run `herdr <args>` and return its stdout, or an error built from stderr.
/// A missing binary or unreachable server is reported as Err, never raised.
async fn herdr_exec(args : Array[String]) -> Result[String, String] {
  let what = if args.length() >= 2 {
    args[0] + " " + args[1]
  } else {
    args.join(" ")
  }
  let (status, out, err) = @proc.exec_cmd_split("herdr", args) catch {
    e => return Err("herdr \{what} failed: \{e} (is herdr installed and running?)")
  }
  if status != 0 {
    return Err("herdr \{what} failed: " + @herdr.parse_error_message(err, out))
  }
  Ok(out)
}

///|
/// Look up the workspace id for a label, if such a workspace is open.
async fn find_workspace(label : String) -> Result[String?, String] {
  let out = match herdr_exec(@herdr.workspace_list_args()) {
    Ok(o) => o
    Err(e) => return Err(e)
  }
  match @herdr.parse_workspace_list(out) {
    Ok(entries) => Ok(@herdr.find_workspace_id(entries, label=label))
    Err(e) => Err(e)
  }
}

///|
/// Set up the panes of a freshly created workspace and focus it.
async fn setup_workspace(
  created : @herdr.CreatedWorkspace,
  workdir : String,
  command : String,
  focus : Bool
) -> Result[Unit, String] {
  // Split before starting the agent so it launches at its final size.
  match herdr_exec(@herdr.pane_split_args(pane_id=created.root_pane_id, cwd=workdir)) {
    Ok(out) =>
      match @herdr.parse_pane_split(out) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  match herdr_exec(@herdr.pane_run_args(pane_id=created.root_pane_id, command=command)) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if !focus {
    return Ok(())
  }
  match herdr_exec(@herdr.workspace_focus_args(created.workspace_id)) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
impl @ports.WorkspaceManager for HerdrWorkspace with open(self, repo_name~, branch~, workdir~, continue_session~, focus~, prompt_file~) {
  let label = @herdr.label(repo_name, branch)
  match find_workspace(label) {
    Ok(Some(workspace_id)) => {
      if !focus {
        return Ok(Reused)
      }
      return match herdr_exec(@herdr.workspace_focus_args(workspace_id)) {
        Ok(_) => Ok(Reused)
        Err(e) => Err(e)
      }
    }
    Ok(None) => ()
    Err(e) => return Err(e)
  }
  let created = match herdr_exec(@herdr.workspace_create_args(cwd=workdir, label=label)) {
    Ok(out) =>
      match @herdr.parse_workspace_create(out) {
        Ok(c) => c
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let command = @prompt.expand_prompt(
    @herdr.select_agent_command(
      new_command=self.agent_command,
      resume_command=self.agent_resume_command,
      continue_session=continue_session,
    ),
    prompt_file,
  )
  match setup_workspace(created, workdir, command, focus) {
    Ok(_) => Ok(Created)
    Err(e) => {
      // Do not leave a half-built workspace behind: a later `open` would only
      // focus it and never start the agent.
      let _ = herdr_exec(@herdr.workspace_close_args(created.workspace_id))
      Err(e)
    }
  }
}

///|
impl @ports.WorkspaceManager for HerdrWorkspace with supports_prompt(self) {
  @prompt.accepts_prompt(self.agent_command) ||
  @prompt.accepts_prompt(self.agent_resume_command)
}

///|
impl @ports.WorkspaceManager for HerdrWorkspace with close(self, name~) {
  let _ = self
  let workspace_id = match find_workspace(name) {
    Ok(Some(id)) => id
    Ok(None) => return Ok(false)
    Err(e) => return Err(e)
  }
  match herdr_exec(@herdr.workspace_close_args(workspace_id)) {
    Ok(_) => Ok(true)
    Err(e) => Err(e)
  }
}

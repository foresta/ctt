///|
/// Adapter that implements the EditorLauncher port using nvim with Claude Code.
pub(all) struct NvimEditor {}

///|
/// Open nvim with Claude Code for the given repository and branch.
impl @ports.EditorLauncher for NvimEditor with open(self, repo_name~, workdir~, branch~, continue_session~) {
  let _ = self
  open_editor(repo_name, workdir, branch, continue_session=continue_session)
  Ok(())
}

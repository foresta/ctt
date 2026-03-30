///|
pub(all) struct NvimEditor {}

///|
impl @ports.EditorLauncher for NvimEditor with open(self, repo_name~, workdir~, branch~, continue_session~) {
  let _ = self
  open_editor(repo_name, workdir, branch, continue_session=continue_session)
  Ok(())
}

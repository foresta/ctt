///|
pub(open) trait EditorLauncher {
  async open(Self, repo_name~ : String, workdir~ : String, branch~ : String, continue_session~ : Bool) -> Result[Unit, String]
}

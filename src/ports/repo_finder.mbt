///|
/// Port for discovering git repositories under a workspace directory.
pub(open) trait RepositoryFinder {
  async find_git_repos(Self, workspace~ : String, max_depth~ : Int) -> Result[Array[String], String]
}

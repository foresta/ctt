///|
/// A worktree with its associated metadata.
pub(all) struct Worktree {
  name : String
  repo_name : String
  branch : String
  workdir : String
}

///|
/// Port for listing and finding worktrees.
pub(open) trait WorktreeRepository {
  list(Self) -> Result[Array[Worktree], String]
  find(Self, name~ : String) -> Result[Worktree?, String]
}

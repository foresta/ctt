///|
/// Lifecycle status of a worktree branch.
pub(all) enum WorktreeStatus {
  InProgress
  PrOpen
  Merged
  NoChanges
} derive(Show, Eq)

///|
/// Aggregated information about a worktree including its git and PR state.
pub(all) struct WorktreeInfo {
  name : String
  status : WorktreeStatus
  branch : String
  uncommitted : Int
  commits_ahead : Int
  pr_url : String
} derive(Show)

///|
/// Returns the display string for this status.
pub fn WorktreeStatus::to_display(self : WorktreeStatus) -> String {
  match self {
    InProgress => "in-progress"
    PrOpen => "pr-open"
    Merged => "merged"
    NoChanges => "no-changes"
  }
}

///|
/// Returns this worktree info as a row of strings for table display.
pub fn WorktreeInfo::to_row(self : WorktreeInfo) -> Array[String] {
  [
    self.name,
    self.status.to_display(),
    self.branch,
    "\{self.uncommitted} changed",
    "\{self.commits_ahead} commits",
    self.pr_url,
  ]
}

///|
/// Local and remote branches available in a repository.
pub(all) struct BranchList {
  local_branches : Array[String]
  remote_branches : Array[String]
}

///|
/// Returns all branches (local + remote), deduplicated.
pub fn BranchList::to_all(self : BranchList) -> Array[String] {
  let all : Array[String] = []
  for b in self.local_branches {
    all.push(b)
  }
  for b in self.remote_branches {
    all.push(b)
  }
  all
}

///|
/// Port for version control operations such as worktree management, branch queries, and mutations.
pub(open) trait VCS {
  repo_marker_name(Self) -> String
  async get_worktree_status(Self, name~ : String, workdir~ : String) -> Result[WorktreeInfo, String]
  async list_branches(Self, repo_dir~ : String) -> Result[BranchList, String]
  async branch_exists(Self, workdir~ : String, branch~ : String) -> Result[Bool, String]
  async list_ignored_files(Self, repo_dir~ : String) -> Result[Array[String], String]
  async create_branch_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String, base_branch~ : String?) -> Result[Unit, String]
  async checkout_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String) -> Result[Unit, String]
  async remove_worktree(Self, workdir~ : String) -> Result[Unit, String]
  async delete_branch(Self, workdir~ : String, branch~ : String, force~ : Bool) -> Result[Unit, String]
}

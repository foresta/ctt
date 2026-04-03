///|
/// Lifecycle status of a task branch.
pub(all) enum TaskStatus {
  InProgress
  PrOpen
  Merged
  NoChanges
} derive(Show, Eq)

///|
/// Aggregated information about a task branch including its git and PR state.
pub(all) struct TaskInfo {
  name : String
  status : TaskStatus
  branch : String
  uncommitted : Int
  commits_ahead : Int
  pr_url : String
} derive(Show)

///|
/// Returns the display string for this status.
pub fn TaskStatus::to_display(self : TaskStatus) -> String {
  match self {
    InProgress => "in-progress"
    PrOpen => "pr-open"
    Merged => "merged"
    NoChanges => "no-changes"
  }
}

///|
/// Returns this task info as a row of strings for table display.
pub fn TaskInfo::to_row(self : TaskInfo) -> Array[String] {
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
/// Port for read-only git repository queries such as branch listing and status checks.
pub(open) trait RepositoryQuery {
  async get_task_status(Self, name~ : String, workdir~ : String) -> Result[TaskInfo, String]
  async list_branches(Self, repo_dir~ : String) -> Result[BranchList, String]
  async common_dir(Self, workdir~ : String) -> Result[String, String]
  async branch_exists(Self, git_dir~ : String, branch~ : String) -> Result[Bool, String]
  async list_ignored_files(Self, repo_dir~ : String) -> Result[Array[String], String]
}

///|
/// Port for mutating git repository state such as creating or removing worktrees and branches.
pub(open) trait RepositoryMutator {
  async create_branch_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String, base_branch~ : String?) -> Result[Unit, String]
  async checkout_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String) -> Result[Unit, String]
  async remove_worktree(Self, git_dir~ : String, workdir~ : String) -> Result[Unit, String]
  async delete_branch(Self, git_dir~ : String, branch~ : String, force~ : Bool) -> Result[Unit, String]
}

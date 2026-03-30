///|
pub(all) enum TaskStatus {
  InProgress
  PrOpen
  Merged
  NoChanges
} derive(Show, Eq)

///|
pub(all) struct TaskInfo {
  status : TaskStatus
  branch : String
  uncommitted : Int
  commits_ahead : Int
  pr_url : String
} derive(Show)

///|
pub(all) struct BranchList {
  local_branches : Array[String]
  remote_branches : Array[String]
}

///|
pub(open) trait RepositoryQuery {
  async get_task_status(Self, workdir~ : String) -> Result[TaskInfo, String]
  async list_branches(Self, repo_dir~ : String) -> Result[BranchList, String]
  async common_dir(Self, workdir~ : String) -> Result[String, String]
  async branch_exists(Self, git_dir~ : String, branch~ : String) -> Result[Bool, String]
  async list_ignored_files(Self, repo_dir~ : String) -> Result[Array[String], String]
}

///|
pub(open) trait RepositoryMutator {
  async create_branch_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String, base_branch~ : String?) -> Result[Unit, String]
  async checkout_worktree(Self, repo_dir~ : String, workdir~ : String, branch~ : String) -> Result[Unit, String]
  async remove_worktree(Self, git_dir~ : String, workdir~ : String) -> Result[Unit, String]
  async delete_branch(Self, git_dir~ : String, branch~ : String, force~ : Bool) -> Result[Unit, String]
}

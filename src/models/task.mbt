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

///|
/// Create a WorktreeRepository that scans the worktree directory on the filesystem.
pub fn new_worktree_repository(
  fs : &@ports.FileSystem,
  workspace_dir : String
) -> &@ports.WorktreeRepository {
  OsWorktreeRepository::{ fs, workspace_dir }
}

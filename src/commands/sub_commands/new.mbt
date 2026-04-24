///|
/// Creates a new task by setting up a git worktree and opening it in the editor.
pub(all) struct NewCommand {
  discovery : @domain.DiscoveryService
  worktree : @domain.WorktreeService
  vcs : &@ports.VCS
  editor : &@ports.EditorLauncher
  fs : &@ports.FileSystem
  workspace_dir : String
}

///|
/// Control flow: repo selection → branch selection → action selection → execute.
impl @ports.Runnable for NewCommand with run(self) {
  let repos = match self.discovery.find_repos(workspace=self.workspace_dir, max_depth=5) {
    Ok(r) => r
    Err(e) => return @ports.Error(e)
  }
  @ports.Select(
    items=repos, prompt="Select Repository> ",
    on_select=async fn(repo_dir) {
      let repo_name = @path.basename(repo_dir)
      let branches = match self.vcs.list_branches(repo_dir=repo_dir) {
        Ok(b) => b.to_all()
        Err(e) => return @ports.Error(e)
      }
      // Step 3: Select branch
      @ports.Select(
        items=branches, prompt="Select Branch for Worktree> ", on_select=fn(branch) {
          @ports.Menu(prompt="Select action> ", options=[
              ("Checkout this branch", async fn() {
                self.checkout_and_open(repo_dir, repo_name, branch)
              }),
              ("Create new branch from this branch", fn() {
                @ports.Input(prompt="New branch name> ", on_input=fn(new_branch) {
                  @ports.Then(
                    first=@ports.Lines(["Creating branch '" + new_branch + "' from '" + branch + "'..."]),
                    next=async fn() {
                      self.create_branch_and_open(
                        repo_dir, repo_name, new_branch, base_branch=branch,
                      )
                    },
                  )
                })
              }),
            ],
          )
        },
      )
    },
  )
}


///|
/// Create a new branch worktree from base, link files, and open editor.
async fn NewCommand::create_branch_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String,
  base_branch~ : String
) -> @ports.CommandResult {
  let workdir = @domain.worktree_path(self.workspace_dir, repo_name, branch)
  if self.fs.path_exists(path=workdir) {
    return @ports.Sequence([
      @ports.Lines(["Directory already exists: " + workdir]),
      @ports.Confirm(
        prompt="Use existing worktree? [y/N] ",
        on_yes=async fn() {
          self.link_and_open(repo_dir, repo_name, workdir, branch, true)
        },
      ),
    ])
  }
  match self.vcs.create_branch_worktree(
    repo_dir=repo_dir, workdir=workdir, branch=branch,
    base_branch=Some(base_branch),
  ) {
    Ok(_) => self.link_and_open(repo_dir, repo_name, workdir, branch, false)
    Err(e) => @ports.Lines(["Error: " + e])
  }
}

///|
/// Checkout an existing branch into a worktree, link files, and open editor.
async fn NewCommand::checkout_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String
) -> @ports.CommandResult {
  let workdir = @domain.worktree_path(self.workspace_dir, repo_name, branch)
  if self.fs.path_exists(path=workdir) {
    return @ports.Sequence([
      @ports.Lines(["Directory already exists: " + workdir]),
      @ports.Confirm(
        prompt="Use existing worktree? [y/N] ",
        on_yes=async fn() {
          self.link_and_open(repo_dir, repo_name, workdir, branch, true)
        },
      ),
    ])
  }
  match self.vcs.checkout_worktree(
    repo_dir=repo_dir, workdir=workdir, branch=branch,
  ) {
    Ok(_) => self.link_and_open(repo_dir, repo_name, workdir, branch, false)
    Err(e) => @ports.Lines(["Error: " + e])
  }
}

///|
/// Link ignored files and open editor.
async fn NewCommand::link_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  workdir : String,
  branch : String,
  continue_session : Bool
) -> @ports.CommandResult {
  let link_messages = self.worktree.link_ignored_files(repo_dir, workdir)
  let _ = self.editor.open(
    repo_name=repo_name, workdir=workdir, branch=branch,
    continue_session=continue_session,
  )
  @ports.Lines(link_messages)
}

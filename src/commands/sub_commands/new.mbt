///|
/// Creates a new task by setting up a git worktree and opening its workspace.
/// Steps answered through `opts` skip their interactive prompt.
pub(all) struct NewCommand {
  discovery : @domain.DiscoveryService
  worktree : @domain.WorktreeService
  vcs : &@ports.VCS
  workspace : &@ports.WorkspaceManager
  fs : &@ports.FileSystem
  workspace_dir : String
  opts : NewOptions
}

///|
/// Control flow: repo selection → branch selection → action selection → execute.
impl @ports.Runnable for NewCommand with run(self) {
  let repos = match self.discovery.find_repos(workspace=self.workspace_dir, max_depth=5) {
    Ok(r) => r
    Err(e) => return @ports.Error(e)
  }
  match self.opts.repo {
    Some(query) =>
      match @domain.resolve_repo(repos, query) {
        Ok(repo_dir) => self.with_repo(repo_dir)
        Err(e) => @ports.Error(e)
      }
    None =>
      @ports.Select(
        items=repos, prompt="Select Repository> ",
        on_select=async fn(repo_dir) { self.with_repo(repo_dir) },
      )
  }
}

///|
/// Branch step: use `--branch` / `--base` when given, otherwise ask.
async fn NewCommand::with_repo(
  self : NewCommand,
  repo_dir : String
) -> @ports.CommandResult {
  let repo_name = @path.basename(repo_dir)
  let branches = match self.vcs.list_branches(repo_dir=repo_dir) {
    Ok(b) => b.to_all()
    Err(e) => return @ports.Error(e)
  }
  match self.opts.branch {
    None =>
      @ports.Select(
        items=branches, prompt="Select Branch for Worktree> ", on_select=fn(branch) {
          self.branch_menu(repo_dir, repo_name, branch)
        },
      )
    Some(branch) =>
      match self.opts.base {
        Some(base) =>
          self.create_branch_and_open(repo_dir, repo_name, branch, base_branch=base)
        None =>
          if branches.contains(branch) {
            self.checkout_and_open(repo_dir, repo_name, branch)
          } else {
            @ports.Error(
              "branch '\{branch}' not found in \{repo_name}; pass --base <branch> to create it",
            )
          }
      }
  }
}

///|
/// Interactive choice between checking out `branch` and branching off it.
fn NewCommand::branch_menu(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String
) -> @ports.CommandResult {
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
  ])
}

///|
/// The worktree directory already exists: reuse it without asking when the
/// branch was given on the command line (after checking it really is a
/// worktree of that branch), otherwise confirm.
async fn NewCommand::reuse_existing(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  workdir : String,
  branch : String
) -> @ports.CommandResult {
  if self.opts.branch is Some(_) {
    match self.vcs.current_branch(workdir=workdir) {
      Ok(b) if b == branch => ()
      Ok(b) =>
        return @ports.Error(
          "directory exists but has branch '\{b}', not '\{branch}': " + workdir,
        )
      Err(e) => return @ports.Error("directory exists but " + e)
    }
    return @ports.Then(
      first=@ports.Lines(["Using existing worktree: " + workdir]),
      next=async fn() {
        self.link_and_open(repo_dir, repo_name, workdir, branch, true)
      },
    )
  }
  @ports.Sequence([
    @ports.Lines(["Directory already exists: " + workdir]),
    @ports.Confirm(
      prompt="Use existing worktree? [y/N] ",
      on_yes=async fn() {
        self.link_and_open(repo_dir, repo_name, workdir, branch, true)
      },
    ),
  ])
}

///|
/// Create a new branch worktree from base, link files, and open the workspace.
async fn NewCommand::create_branch_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String,
  base_branch~ : String
) -> @ports.CommandResult {
  let workdir = @domain.worktree_path(self.workspace_dir, repo_name, branch)
  if self.fs.path_exists(path=workdir) {
    return self.reuse_existing(repo_dir, repo_name, workdir, branch)
  }
  match self.vcs.create_branch_worktree(
    repo_dir=repo_dir, workdir=workdir, branch=branch,
    base_branch=Some(base_branch),
  ) {
    Ok(_) => self.link_and_open(repo_dir, repo_name, workdir, branch, false)
    Err(e) => @ports.Error(e)
  }
}

///|
/// Checkout an existing branch into a worktree, link files, and open the workspace.
async fn NewCommand::checkout_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String
) -> @ports.CommandResult {
  let workdir = @domain.worktree_path(self.workspace_dir, repo_name, branch)
  if self.fs.path_exists(path=workdir) {
    return self.reuse_existing(repo_dir, repo_name, workdir, branch)
  }
  match self.vcs.checkout_worktree(
    repo_dir=repo_dir, workdir=workdir, branch=branch,
  ) {
    Ok(_) => self.link_and_open(repo_dir, repo_name, workdir, branch, false)
    Err(e) => @ports.Error(e)
  }
}

///|
/// Link ignored files and open the workspace. Always ends with a
/// `Worktree: <path>` line so callers can find the directory.
async fn NewCommand::link_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  workdir : String,
  branch : String,
  continue_session : Bool
) -> @ports.CommandResult {
  let lines = self.worktree.link_ignored_files(repo_dir, workdir)
  lines.push("Worktree: " + workdir)
  match self.workspace.open(
    repo_name=repo_name, branch=branch, workdir=workdir,
    continue_session=continue_session, focus=self.opts.focus,
  ) {
    Ok(_) => @ports.Lines(lines)
    Err(e) => @ports.Sequence([@ports.Lines(lines), @ports.Error(e)])
  }
}

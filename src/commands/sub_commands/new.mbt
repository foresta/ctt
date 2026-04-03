///|
/// Creates a new task by setting up a git worktree and opening it in the editor.
pub(all) struct NewCommand {
  repo_query : &@ports.RepositoryQuery
  repo_mutator : &@ports.RepositoryMutator
  editor : &@ports.EditorLauncher
  fs : &@ports.FileSystem
  repo_finder : &@ports.RepositoryFinder
  workspace_dir : String
  config_dir : String
}

///|
/// Control flow: repo selection → branch selection → action selection → execute.
impl @ports.Runnable for NewCommand with run(self) {
  // Step 1: Discover repositories
  let repos = match self.repo_finder.find_git_repos(
    workspace=self.workspace_dir, max_depth=5,
  ) {
    Ok(r) => r
    Err(e) => return @ports.Error(e)
  }
  if repos.is_empty() {
    return @ports.Error("no repositories found")
  }
  // Step 2: Select repository
  @ports.Select(
    items=repos, prompt="Select Repository> ",
    accept_empty=false,
    on_select=async fn(repo_dir) {
      let repo_name = extract_repo_name(repo_dir)
      let branches = self.list_all_branches(repo_dir)
      // Step 3: Select branch
      @ports.Select(
        items=branches, prompt="Select Branch for Worktree> ",
        accept_empty=false,
        on_select=fn(branch) {
          let actions = [
            "Checkout this branch",
            "Create new branch from this branch",
          ]
          // Step 4: Select action
          @ports.Select(
            items=actions, prompt="Select action> ",
            accept_empty=false,
            on_select=async fn(action) {
              // Step 5: Execute
              self.execute(repo_dir, repo_name, branch, action)
            },
          )
        },
      )
    },
  )
}

///|
fn extract_repo_name(repo_dir : String) -> String {
  match repo_dir.rev_find("/") {
    Some(idx) => repo_dir[idx + 1:].to_string()
    None => repo_dir
  }
}

///|
/// List all local and remote branches, deduplicated.
async fn NewCommand::list_all_branches(
  self : NewCommand,
  repo_dir : String
) -> Array[String] {
  let branches = match self.repo_query.list_branches(repo_dir=repo_dir) {
    Ok(b) => b
    Err(_) => return []
  }
  let all : Array[String] = []
  for b in branches.local_branches {
    all.push(b)
  }
  for b in branches.remote_branches {
    all.push(b)
  }
  all
}

///|
/// Execute the selected action: checkout existing or create new branch worktree.
async fn NewCommand::execute(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String,
  action : String
) -> @ports.CommandResult {
  let wt_dir = @task.worktree_dir(self.workspace_dir)
  if action == "Create new branch from this branch" {
    @ports.Input(
      prompt="New branch name> ",
      on_input=fn(new_branch) {
        @ports.WithMessage(
          message=["Creating branch '" + new_branch + "' from '" + branch + "'..."],
          next=async fn() {
            self.create_branch_and_open(
              repo_dir, repo_name, new_branch, wt_dir, base_branch=branch,
            )
          },
        )
      },
    )
  } else {
    self.checkout_and_open(repo_dir, repo_name, branch, wt_dir)
  }
}

///|
/// Create a new branch worktree from base, link files, and open editor.
async fn NewCommand::create_branch_and_open(
  self : NewCommand,
  repo_dir : String,
  repo_name : String,
  branch : String,
  wt_dir : String,
  base_branch~ : String
) -> @ports.CommandResult {
  let workdir = wt_dir + "/" + repo_name + "__" + branch
  if self.fs.path_exists(path=workdir) {
    return @ports.Sequence(
      @ports.Lines(["Directory already exists: " + workdir]),
      @ports.Confirm(
        prompt="Use existing worktree? [y/N] ",
        on_yes=async fn() {
          self.link_and_open(repo_dir, repo_name, workdir, branch, true)
        },
      ),
    )
  }
  match self.repo_mutator.create_branch_worktree(
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
  branch : String,
  wt_dir : String
) -> @ports.CommandResult {
  let workdir = wt_dir + "/" + repo_name + "__" + branch
  if self.fs.path_exists(path=workdir) {
    return @ports.Sequence(
      @ports.Lines(["Directory already exists: " + workdir]),
      @ports.Confirm(
        prompt="Use existing worktree? [y/N] ",
        on_yes=async fn() {
          self.link_and_open(repo_dir, repo_name, workdir, branch, true)
        },
      ),
    )
  }
  match self.repo_mutator.checkout_worktree(
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
  let link_messages = self.do_link_ignored_files(repo_dir, workdir)
  let _ = self.editor.open(
    repo_name=repo_name, workdir=workdir, branch=branch,
    continue_session=continue_session,
  )
  @ports.Lines(link_messages)
}

///|
/// Symlink git-ignored files from repo into worktree. Returns status messages.
async fn NewCommand::do_link_ignored_files(
  self : NewCommand,
  repo_dir : String,
  workdir : String
) -> Array[String] {
  let output : Array[String] = []
  let ignore_file = self.config_dir + "/.worktree-link-ignore"
  let skip_patterns : Array[String] = []
  if self.fs.path_exists(path=ignore_file) {
    match self.fs.read_file_to_string(path=ignore_file) {
      Ok(content) =>
        for part in content.split("\n") {
          let line = part.to_string().trim_end().to_string()
          if line != "" && not(line.has_prefix("#")) {
            skip_patterns.push(line)
          }
        }
      Err(_) => ()
    }
  }
  let ignored = match self.repo_query.list_ignored_files(repo_dir=repo_dir) {
    Ok(files) => files
    Err(_) => return output
  }
  let mut linked = 0
  for path in ignored {
    let src = repo_dir + "/" + path
    let dst = workdir + "/" + path
    if not(self.fs.path_exists(path=src)) {
      continue
    }
    let mut skip = false
    for pattern in skip_patterns {
      if path == pattern {
        skip = true
        break
      }
    }
    if skip || self.fs.path_exists(path=dst) {
      continue
    }
    let dst_dir = match dst.rev_find("/") {
      Some(idx) => dst[:idx].to_string()
      None => dst
    }
    if not(self.fs.path_exists(path=dst_dir)) {
      let _ = self.fs.create_dir(path=dst_dir)
    }
    let is_dir = match self.fs.is_dir(path=src) {
      Ok(d) => d
      Err(_) => false
    }
    if is_dir {
      let _ = self.fs.create_dir(path=dst)
      match self.fs.read_dir(path=src) {
        Ok(children) =>
          for child in children {
            let child_dst = dst + "/" + child
            if not(self.fs.path_exists(path=child_dst)) {
              let child_src = src + "/" + child
              let _ = self.fs.create_symlink(src=child_src, dst=child_dst)
            }
          }
        Err(_) => ()
      }
    } else {
      let _ = self.fs.create_symlink(src=src, dst=dst)
    }
    linked = linked + 1
    output.push("Linked: " + path)
  }
  if linked > 0 {
    output.push("Linked " + linked.to_string() + " ignored file(s) into worktree.")
  }
  output
}

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
/// Returns a Select chain: repo → branch → action → worktree creation → editor.
impl @ports.Runnable for NewCommand with run(self) {
  let repos = match self.repo_finder.find_git_repos(
    workspace=self.workspace_dir,
    max_depth=5,
  ) {
    Ok(r) => r
    Err(e) => raise @builtin.Failure(e)
  }
  if repos.is_empty() {
    raise @builtin.Failure("no repositories found")
  }
  let repo_query = self.repo_query
  let repo_mutator = self.repo_mutator
  let editor = self.editor
  let fs = self.fs
  let workspace_dir = self.workspace_dir
  let config_dir = self.config_dir
  @ports.Select(
    message=[],
    items=repos,
    prompt="Select Repository> ",
    on_select=async fn(repo_dir) {
      new_after_repo(
        repo_query, repo_mutator, editor, fs, workspace_dir, config_dir,
        repo_dir,
      )
    },
  )
}

///|
/// After repo selection: list branches and present Select.
async fn new_after_repo(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  workspace_dir : String,
  config_dir : String,
  repo_dir : String
) -> @ports.CommandResult {
  let repo_name = match repo_dir.rev_find("/") {
    Some(idx) => repo_dir[idx + 1:].to_string()
    None => repo_dir
  }
  let branches = match repo_query.list_branches(repo_dir=repo_dir) {
    Ok(b) => b
    Err(e) => return @ports.Lines(["Error: " + e])
  }
  let all_branches : Array[String] = []
  for b in branches.local_branches {
    all_branches.push(b)
  }
  for b in branches.remote_branches {
    all_branches.push(b)
  }
  @ports.Select(
    message=[],
    items=all_branches,
    prompt="Select or Type Branch for Worktree> ",
    on_select=fn(branch) {
      // Existing branch selected → ask action
      let actions = [
        "Checkout this branch",
        "Create new branch from this branch",
      ]
      @ports.Select(
        message=[],
        items=actions,
        prompt="Select action> ",
        on_select=async fn(action) {
          new_after_action(
            repo_query, repo_mutator, editor, fs, workspace_dir, config_dir,
            repo_dir, repo_name, branch, action,
          )
        },
      )
    },
  )
}

///|
/// After action selection: create worktree and open editor.
async fn new_after_action(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  workspace_dir : String,
  config_dir : String,
  repo_dir : String,
  repo_name : String,
  branch : String,
  action : String
) -> @ports.CommandResult {
  let wt_dir = @task.worktree_dir(workspace_dir)
  if action == "Create new branch from this branch" {
    // Need new branch name - use Confirm as a prompt placeholder
    // For now, create with branch name directly since we can't do text input via CommandResult
    // TODO: Add a TextInput variant to CommandResult for free-text input
    new_create_worktree(
      repo_query, repo_mutator, editor, fs, config_dir,
      repo_dir, repo_name, branch, wt_dir, Some(branch),
    )
  } else {
    // Checkout existing branch
    let workdir = wt_dir + "/" + repo_name + "__" + branch
    if fs.path_exists(path=workdir) {
      @ports.Confirm(
        message=[
          "Directory already exists: " + workdir,
        ],
        prompt="Use existing worktree? [y/N] ",
        on_yes=async fn() {
          link_and_open(
            repo_query, editor, fs, config_dir, repo_dir, repo_name, workdir,
            branch, true,
          )
        },
      )
    } else {
      match repo_mutator.checkout_worktree(
        repo_dir=repo_dir,
        workdir=workdir,
        branch=branch,
      ) {
        Ok(_) =>
          link_and_open(
            repo_query, editor, fs, config_dir, repo_dir, repo_name, workdir,
            branch, false,
          )
        Err(e) => @ports.Lines(["Error: " + e])
      }
    }
  }
}

///|
/// Create a new branch worktree.
async fn new_create_worktree(
  repo_query : &@ports.RepositoryQuery,
  repo_mutator : &@ports.RepositoryMutator,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  config_dir : String,
  repo_dir : String,
  repo_name : String,
  branch : String,
  wt_dir : String,
  base_branch : String?
) -> @ports.CommandResult {
  let workdir = wt_dir + "/" + repo_name + "__" + branch
  if fs.path_exists(path=workdir) {
    return @ports.Confirm(
      message=["Directory already exists: " + workdir],
      prompt="Use existing worktree? [y/N] ",
      on_yes=async fn() {
        link_and_open(
          repo_query, editor, fs, config_dir, repo_dir, repo_name, workdir,
          branch, true,
        )
      },
    )
  }
  match repo_mutator.create_branch_worktree(
    repo_dir=repo_dir,
    workdir=workdir,
    branch=branch,
    base_branch=base_branch,
  ) {
    Ok(_) =>
      link_and_open(
        repo_query, editor, fs, config_dir, repo_dir, repo_name, workdir,
        branch, false,
      )
    Err(e) => @ports.Lines(["Error: " + e])
  }
}

///|
/// Link ignored files and open editor. Returns result Lines.
async fn link_and_open(
  repo_query : &@ports.RepositoryQuery,
  editor : &@ports.EditorLauncher,
  fs : &@ports.FileSystem,
  config_dir : String,
  repo_dir : String,
  repo_name : String,
  workdir : String,
  branch : String,
  continue_session : Bool
) -> @ports.CommandResult {
  let link_messages = do_link_ignored_files(
    repo_query, fs, config_dir, repo_dir, workdir,
  )
  let _ = editor.open(
    repo_name=repo_name,
    workdir=workdir,
    branch=branch,
    continue_session=continue_session,
  )
  let output : Array[String] = []
  output.append(link_messages)
  @ports.Lines(output)
}

///|
/// Symlink git-ignored files from repo into worktree. Returns status messages.
async fn do_link_ignored_files(
  repo_query : &@ports.RepositoryQuery,
  fs : &@ports.FileSystem,
  config_dir : String,
  repo_dir : String,
  workdir : String
) -> Array[String] {
  let output : Array[String] = []
  let ignore_file = config_dir + "/.worktree-link-ignore"
  let skip_patterns : Array[String] = []
  if fs.path_exists(path=ignore_file) {
    match fs.read_file_to_string(path=ignore_file) {
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
  let ignored = match repo_query.list_ignored_files(repo_dir=repo_dir) {
    Ok(files) => files
    Err(_) => return output
  }
  let mut linked = 0
  for path in ignored {
    let src = repo_dir + "/" + path
    let dst = workdir + "/" + path
    if not(fs.path_exists(path=src)) {
      continue
    }
    let mut skip = false
    for pattern in skip_patterns {
      if path == pattern {
        skip = true
        break
      }
    }
    if skip || fs.path_exists(path=dst) {
      continue
    }
    let dst_dir = match dst.rev_find("/") {
      Some(idx) => dst[:idx].to_string()
      None => dst
    }
    if not(fs.path_exists(path=dst_dir)) {
      let _ = fs.create_dir(path=dst_dir)
    }
    let is_dir = match fs.is_dir(path=src) {
      Ok(d) => d
      Err(_) => false
    }
    if is_dir {
      let _ = fs.create_dir(path=dst)
      match fs.read_dir(path=src) {
        Ok(children) =>
          for child in children {
            let child_dst = dst + "/" + child
            if not(fs.path_exists(path=child_dst)) {
              let child_src = src + "/" + child
              let _ = fs.create_symlink(src=child_src, dst=child_dst)
            }
          }
        Err(_) => ()
      }
    } else {
      let _ = fs.create_symlink(src=src, dst=dst)
    }
    linked = linked + 1
    output.push("Linked: " + path)
  }
  if linked > 0 {
    output.push("Linked " + linked.to_string() + " ignored file(s) into worktree.")
  }
  output
}

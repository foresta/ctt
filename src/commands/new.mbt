///|
/// Creates a new task by setting up a git worktree and opening it in the editor.
pub(all) struct NewCommand {
  selector : &@ports.ItemSelector
  prompter : &@ports.UserPrompter
  repo_query : &@ports.RepositoryQuery
  repo_mutator : &@ports.RepositoryMutator
  editor : &@ports.EditorLauncher
  fs : &@ports.FileSystem
  repo_finder : &@ports.RepositoryFinder
  workspace_dir : String
  config_dir : String
}

///|
/// Guides the user through repo selection, branch selection, worktree creation, and editor launch.
impl Runnable for NewCommand with run(self) {
  // Select repository
  let repo_dir = match self.select_repo() {
    Ok(r) => r
    Err(e) => { println("Error: \{e}"); return }
  }
  let repo_name = match repo_dir.rev_find("/") {
    Some(idx) => repo_dir[idx + 1:].to_string()
    None => repo_dir
  }
  // Select branch
  let (branch, is_existing) = match self.select_branch(repo_dir) {
    Ok(r) => r
    Err(e) => { println("Error: \{e}"); return }
  }
  let wt_dir = @task.worktree_dir(self.workspace_dir)
  if is_existing {
    // Ask what to do with existing branch
    let action = match self.ask_branch_action() {
      Ok(a) => a
      Err(e) => { println("Error: \{e}"); return }
    }
    if action == "new_from_base" {
      let new_name = match self.input_new_branch_name() {
        Ok(n) => n
        Err(e) => { println("Error: \{e}"); return }
      }
      let workdir = "\{wt_dir}/\{repo_name}__\{new_name}"
      if self.fs.path_exists(path=workdir) {
        match self.prompter.confirm(
          prompt="Directory already exists: \{workdir} — Use existing worktree? [y/N] ",
        ) {
          Ok(true) => {
            self.link_ignored_files(repo_dir, workdir)
            let _ = self.editor.open(
              repo_name=repo_name,
              workdir=workdir,
              branch=new_name,
              continue_session=true,
            )
            return
          }
          _ => { println("Cancelled."); return }
        }
      }
      match self.repo_mutator.create_branch_worktree(
        repo_dir=repo_dir,
        workdir=workdir,
        branch=new_name,
        base_branch=Some(branch),
      ) {
        Ok(_) => {
          self.link_ignored_files(repo_dir, workdir)
          let _ = self.editor.open(
            repo_name=repo_name,
            workdir=workdir,
            branch=new_name,
            continue_session=false,
          )
        }
        Err(e) => println("Error: \{e}")
      }
    } else {
      // Checkout existing branch
      let workdir = "\{wt_dir}/\{repo_name}__\{branch}"
      if self.fs.path_exists(path=workdir) {
        match self.prompter.confirm(
          prompt="Directory already exists: \{workdir} — Use existing worktree? [y/N] ",
        ) {
          Ok(true) => {
            self.link_ignored_files(repo_dir, workdir)
            let _ = self.editor.open(
              repo_name=repo_name,
              workdir=workdir,
              branch=branch,
              continue_session=true,
            )
            return
          }
          _ => { println("Cancelled."); return }
        }
      }
      match self.repo_mutator.checkout_worktree(
        repo_dir=repo_dir,
        workdir=workdir,
        branch=branch,
      ) {
        Ok(_) => {
          self.link_ignored_files(repo_dir, workdir)
          let _ = self.editor.open(
            repo_name=repo_name,
            workdir=workdir,
            branch=branch,
            continue_session=false,
          )
        }
        Err(e) => println("Error: \{e}")
      }
    }
  } else {
    // New branch (typed in fzf)
    let workdir = "\{wt_dir}/\{repo_name}__\{branch}"
    if self.fs.path_exists(path=workdir) {
      match self.prompter.confirm(
        prompt="Directory already exists: \{workdir} — Use existing worktree? [y/N] ",
      ) {
        Ok(true) => {
          self.link_ignored_files(repo_dir, workdir)
          let _ = self.editor.open(
            repo_name=repo_name,
            workdir=workdir,
            branch=branch,
            continue_session=true,
          )
          return
        }
        _ => { println("Cancelled."); return }
      }
    }
    match self.repo_mutator.create_branch_worktree(
      repo_dir=repo_dir,
      workdir=workdir,
      branch=branch,
      base_branch=None,
    ) {
      Ok(_) => {
        self.link_ignored_files(repo_dir, workdir)
        let _ = self.editor.open(
          repo_name=repo_name,
          workdir=workdir,
          branch=branch,
          continue_session=false,
        )
      }
      Err(e) => println("Error: \{e}")
    }
  }
}

///|
/// Discovers git repositories in the workspace and prompts the user to pick one.
async fn NewCommand::select_repo(self : NewCommand) -> Result[String, String] {
  let repos = match self.repo_finder.find_git_repos(
    workspace=self.workspace_dir,
    max_depth=5,
  ) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  if repos.is_empty() {
    return Err("no repositories found")
  }
  match self.selector.select(items=repos, prompt="Select Repository> ") {
    Ok(Some(repo)) => Ok(repo)
    Ok(None) => Err("cancelled")
    Err(e) => Err(e)
  }
}

///|
/// Lists local and remote branches for selection. Returns the branch name and whether it already exists.
async fn NewCommand::select_branch(
  self : NewCommand,
  repo_dir : String
) -> Result[(String, Bool), String] {
  let branches = match self.repo_query.list_branches(repo_dir=repo_dir) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  let all_branches : Array[String] = []
  for b in branches.local_branches {
    all_branches.push(b)
  }
  for b in branches.remote_branches {
    all_branches.push(b)
  }
  match self.selector.select_with_query(
    items=all_branches,
    prompt="Select or Type Branch for Worktree> ",
  ) {
    Ok(result) =>
      match result.selected {
        Some(branch) => Ok((branch, true))
        None =>
          if result.query != "" {
            Ok((result.query, false))
          } else {
            Err("cancelled")
          }
      }
    Err(e) => Err(e)
  }
}

///|
/// Asks the user whether to checkout an existing branch or create a new branch from it.
async fn NewCommand::ask_branch_action(
  self : NewCommand
) -> Result[String, String] {
  let options = [
    "Checkout this branch",
    "Create new branch from this branch",
  ]
  match self.selector.select(items=options, prompt="Select action> ") {
    Ok(Some("Checkout this branch")) => Ok("checkout")
    Ok(Some("Create new branch from this branch")) => Ok("new_from_base")
    Ok(_) => Err("cancelled")
    Err(e) => Err(e)
  }
}

///|
/// Prompts the user to type a new branch name.
async fn NewCommand::input_new_branch_name(
  self : NewCommand
) -> Result[String, String] {
  match self.prompter.read_line(prompt="New branch name> ") {
    Ok(name) =>
      if name == "" {
        Err("cancelled")
      } else {
        Ok(name)
      }
    Err(e) => Err(e)
  }
}

///|
/// Symlinks git-ignored files from the source repo into the new worktree, respecting skip patterns from `.worktree-link-ignore`.
async fn NewCommand::link_ignored_files(
  self : NewCommand,
  repo_dir : String,
  workdir : String
) -> Unit {
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
    Err(_) => return
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
    if skip {
      continue
    }
    if self.fs.path_exists(path=dst) {
      continue
    }
    // Create parent directory
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
    println("Linked: \{path}")
  }
  if linked > 0 {
    println("Linked \{linked} ignored file(s) into worktree.")
  }
}

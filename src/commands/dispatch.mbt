///|
pub fn dispatch(
  input : CommandInput,
  svc : Services,
  cfg : AppConfig
) -> &Runnable {
  match input.command {
    Ls => (LsCommand::{ tasks: svc.tasks } : &Runnable)
    Open =>
      (OpenCommand::{
        selector: svc.selector,
        editor: svc.editor,
        tasks: svc.tasks,
      } : &Runnable)
    Status =>
      (StatusCommand::{
        selector: svc.selector,
        repo: svc.repo_query,
        tasks: svc.tasks,
        params: input.params,
      } : &Runnable)
    Done =>
      (DoneCommand::{
        selector: svc.selector,
        prompter: svc.prompter,
        repo_query: svc.repo_query,
        repo_mutator: svc.repo_mutator,
        session: svc.session,
        tasks: svc.tasks,
      } : &Runnable)
    New =>
      (NewCommand::{
        selector: svc.selector,
        prompter: svc.prompter,
        repo_query: svc.repo_query,
        repo_mutator: svc.repo_mutator,
        editor: svc.editor,
        fs: svc.fs,
        repo_finder: svc.repo_finder,
        workspace_dir: cfg.workspace_dir,
        config_dir: cfg.config_dir,
      } : &Runnable)
  }
}

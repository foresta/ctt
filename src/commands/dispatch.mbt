///|
pub fn dispatch(input : CommandInput) -> &Runnable {
  match input.command {
    Ls => (LsCommand::{  } : &Runnable)
    Open => (OpenCommand::{  } : &Runnable)
    Status => (StatusCommand::{ params: input.params } : &Runnable)
    Done => (DoneCommand::{  } : &Runnable)
    New => (NewCommand::{  } : &Runnable)
  }
}

///|
pub(all) enum Command {
  Ls
  Open
  Status
  Done
  New
}

///|
pub(all) struct CommandInput {
  command : Command
  params : Array[String]
}

///|
pub(open) trait Runnable {
  async run(Self) -> Unit raise
}

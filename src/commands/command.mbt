///|
/// Available CLI subcommands.
pub(all) enum Command {
  Ls
  Open
  Status
  Done
  New
  Help
  Version
}

///|
/// Parsed CLI input containing the resolved command and its parameters.
pub(all) struct CommandInput {
  command : Command
  params : Array[String]
}

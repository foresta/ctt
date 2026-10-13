///|
/// Available CLI subcommands with their parsed options.
pub(all) enum Command {
  Ls
  Open(@sub_commands.OpenOptions)
  Status(@sub_commands.StatusOptions)
  Done(@sub_commands.DoneOptions)
  New(@sub_commands.NewOptions)
  Help
  Version
  /// Argument error: the message is reported and the process exits with 1.
  Usage(String)
}

///|
/// Parsed CLI input.
pub(all) struct CommandInput {
  command : Command
}

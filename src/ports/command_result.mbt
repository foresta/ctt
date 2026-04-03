///|
/// Result returned by a command's run() method.
/// Represents output data and interactive steps as a pure data structure.
/// The render layer (main) interprets this to perform actual I/O.
pub(all) enum CommandResult {
  /// Display lines of text.
  Lines(Array[String])
  /// Display a formatted table (array of rows, each row is array of cells).
  Table(Array[Array[String]])
  /// No output.
  Empty
  /// An error message to display.
  Error(String)
  /// Show a message, then ask the user for yes/no confirmation.
  /// If yes, evaluate the continuation to get the next result.
  Confirm(
    message~ : Array[String],
    prompt~ : String,
    on_yes~ : async () -> CommandResult,
  )
  /// Show a message, then ask the user to select from a list.
  /// Pass the selected item to the continuation to get the next result.
  Select(
    message~ : Array[String],
    items~ : Array[String],
    prompt~ : String,
    on_select~ : async (String) -> CommandResult,
  )
}

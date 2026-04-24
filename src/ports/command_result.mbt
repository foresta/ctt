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
  /// Execute multiple CommandResults sequentially.
  Sequence(Array[CommandResult])
  /// Execute a CommandResult, then lazily evaluate the next.
  Then(
    first~ : CommandResult,
    next~ : async () -> CommandResult,
  )
  /// Ask the user for yes/no confirmation.
  /// If yes, evaluate the continuation to get the next result.
  Confirm(
    prompt~ : String,
    on_yes~ : async () -> CommandResult,
  )
  /// Ask the user to select from a list.
  /// Pass the selected item to the continuation to get the next result.
  Select(
    items~ : Array[String],
    prompt~ : String,
    on_select~ : async (String) -> CommandResult,
  )
  /// Present a menu of actions. Each option has a label and a callback.
  Menu(
    prompt~ : String,
    options~ : Array[(String, async () -> CommandResult)],
  )
  /// Ask the user for free-text input.
  /// Pass the entered text to the continuation to get the next result.
  Input(
    prompt~ : String,
    on_input~ : async (String) -> CommandResult,
  )
}

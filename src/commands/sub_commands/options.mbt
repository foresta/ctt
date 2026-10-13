///|
/// Options for `ctt new`. `None` means "ask interactively".
pub(all) struct NewOptions {
  repo : String?
  branch : String?
  base : String?
  focus : Bool
  /// Task context handed to the agent as its first prompt (text or URL).
  context : String?
  /// File to read the context from (`-` for stdin); resolved into `context` before dispatch.
  context_file : String?
}

///|
/// Options for `ctt open`.
pub(all) struct OpenOptions {
  name : String?
  focus : Bool
}

///|
/// Options for `ctt done`.
pub(all) struct DoneOptions {
  name : String?
  yes : Bool
  delete_branch : Bool
}

///|
/// Options for `ctt status`.
pub(all) struct StatusOptions {
  all : Bool
  name : String?
}

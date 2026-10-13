///|
/// Options for `ctt new`. `None` means "ask interactively".
pub(all) struct NewOptions {
  repo : String?
  branch : String?
  base : String?
  focus : Bool
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

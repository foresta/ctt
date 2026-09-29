///|
/// Returns the last component of a path.
/// e.g. "/home/user/project" -> "project"
pub fn basename(path : String) -> String {
  match path.rev_find("/") {
    Some(idx) => path[idx + 1:].to_owned()
    None => path
  }
}

///|
/// Returns the parent directory of a path.
/// e.g. "/home/user/project" -> "/home/user"
pub fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(idx) => path[:idx].to_owned()
    None => path
  }
}

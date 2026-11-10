///|
/// A task title is one short line; surrounding whitespace is dropped.
pub fn normalize(text : String) -> Result[String, String] {
  let t = text.trim().to_owned()
  if t == "" {
    return Err("title must not be empty")
  }
  if t.contains("\n") || t.contains("\r") {
    return Err("title must be a single line")
  }
  Ok(t)
}

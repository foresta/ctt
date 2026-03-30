///|
/// Adapter that implements the UserPrompter port using shell stdin.
pub(all) struct ShellPrompter {}

///|
/// Ask a yes/no question and return true for y/Y.
impl @ports.UserPrompter for ShellPrompter with confirm(self, prompt~) {
  let _ = self
  let answer = read_line(prompt)
  Ok(answer == "y" || answer == "Y")
}

///|
/// Read a single line of text from the user.
impl @ports.UserPrompter for ShellPrompter with read_line(self, prompt~) {
  let _ = self
  Ok(read_line(prompt))
}

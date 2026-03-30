///|
pub(all) struct ShellPrompter {}

///|
impl @ports.UserPrompter for ShellPrompter with confirm(self, prompt~) {
  let _ = self
  let answer = read_line(prompt)
  Ok(answer == "y" || answer == "Y")
}

///|
impl @ports.UserPrompter for ShellPrompter with read_line(self, prompt~) {
  let _ = self
  Ok(read_line(prompt))
}

///|
/// Adapter that implements the UserPrompter port using shell stdin.
pub(all) struct ShellPrompter {}

///|
/// Ask a yes/no question and return true for y/Y.
impl @ports.UserPrompter for ShellPrompter with confirm(self, prompt~) {
  let _ = self
  println(prompt)
  let (_, output) = exec_cmd(
    "sh",
    ["-c", "read line && echo \"$line\""],
  )
  let answer = output.trim_end().to_string()
  Ok(answer == "y" || answer == "Y")
}

///|
/// Read a single line of text from the user.
impl @ports.UserPrompter for ShellPrompter with read_line(self, prompt~) {
  let _ = self
  println(prompt)
  let (_, output) = exec_cmd(
    "sh",
    ["-c", "read line && echo \"$line\""],
  )
  Ok(output.trim_end().to_string())
}

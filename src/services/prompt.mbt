///|
/// Read a line from stdin (synchronous, blocking)
pub async fn read_line(prompt : String) -> String {
  // Print prompt to stderr so it doesn't interfere with piping
  println(prompt)
  let (_, output) = @process.collect_output_merged(
    "sh",
    ["-c", "read line && echo \"$line\""],
  )
  output.text().trim_end().to_string()
}

///|
/// Ask a yes/no question, returns true for y/Y
pub async fn confirm(prompt : String) -> Bool {
  let answer = read_line(prompt)
  answer == "y" || answer == "Y"
}

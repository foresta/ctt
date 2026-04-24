///|
/// Adapter that provides console I/O via stdout and stdin.
/// Implements both Renderer (output) and UserPrompter (input) ports.
pub(all) struct Console {}

///|
/// Pads a string with trailing spaces to reach the given width.
fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let buf = StringBuilder::new()
  buf.write_string(s)
  for i = len; i < width; i = i + 1 {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
pub impl @ports.Renderer for Console with print_lines(self, lines) {
  ignore(self)
  lines.each(fn(l) { println(l) })
}

///|
pub impl @ports.Renderer for Console with print_table(self, rows) {
  ignore(self)
  let col_count = rows[0].length()
  let widths = Array::make(col_count, 0)
  for row in rows {
    for i, cell in row {
      if cell.length() > widths[i] {
        widths[i] = cell.length()
      }
    }
  }
  for row in rows {
    let buf = StringBuilder::new()
    for i, cell in row {
      if i > 0 {
        buf.write_string("  ")
      }
      if i < col_count - 1 {
        buf.write_string(pad_right(cell, widths[i]))
      } else {
        buf.write_string(cell)
      }
    }
    println(buf.to_string())
  }
}

///|
pub impl @ports.Renderer for Console with print_error(self, msg) {
  ignore(self)
  println("Error: " + msg)
}

///|
pub impl @ports.Renderer for Console with print_cancelled(self) {
  ignore(self)
  println("Cancelled.")
}

///|
/// Ask a yes/no question and return true for y/Y.
pub impl @ports.UserPrompter for Console with confirm(self, prompt~) {
  let _ = self
  println(prompt)
  let (_, output) = @proc.exec_cmd(
    "sh",
    ["-c", "read line && echo \"$line\""],
  )
  let answer = output.trim_end().to_string()
  Ok(answer == "y" || answer == "Y")
}

///|
/// Read a single line of text from the user.
pub impl @ports.UserPrompter for Console with read_line(self, prompt~) {
  let _ = self
  println(prompt)
  let (_, output) = @proc.exec_cmd(
    "sh",
    ["-c", "read line && echo \"$line\""],
  )
  Ok(output.trim_end().to_string())
}

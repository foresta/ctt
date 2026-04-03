///|
/// Adapter that renders command output to the console via stdout.
pub(all) struct ConsoleRenderer {}

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
impl @ports.Renderer for ConsoleRenderer with print_lines(self, lines) {
  ignore(self)
  lines.each(fn(l) { println(l) })
}

///|
impl @ports.Renderer for ConsoleRenderer with print_table(self, rows) {
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
impl @ports.Renderer for ConsoleRenderer with print_error(self, msg) {
  ignore(self)
  println("Error: " + msg)
}

///|
impl @ports.Renderer for ConsoleRenderer with print_cancelled(self) {
  ignore(self)
  println("Cancelled.")
}

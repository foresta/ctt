///|
/// Adapter that implements the ItemSelector port using fzf.
pub(all) struct FzfSelector {}

///|
/// Select a single item from the list using fzf.
impl @ports.ItemSelector for FzfSelector with select(self, items~, prompt~) {
  let _ = self
  let input = items.join("\n")
  let (read_end, write_end) = @pipe.pipe()
  write_end.write(input)
  write_end.close()
  let args : Array[String] = ["--prompt=\{prompt}", "--bind=enter:accept-non-empty"]
  let (status, output) = @proc.exec_cmd_stdout(
    "fzf",
    args,
    stdin=read_end,
  )
  read_end.close()
  if status != 0 {
    return Ok(None)
  }
  let result = output.trim_end().to_string()
  Ok(if result == "" { None } else { Some(result) })
}

///|
/// Select an item with query text returned alongside the selection.
impl @ports.ItemSelector for FzfSelector with select_with_query(self, items~, prompt~) {
  let _ = self
  let input = items.join("\n")
  let (read_end, write_end) = @pipe.pipe()
  write_end.write(input)
  write_end.close()
  let (_, output) = @proc.exec_cmd_stdout(
    "fzf",
    ["--print-query", "--prompt=\{prompt}"],
    stdin=read_end,
  )
  read_end.close()
  let text = output.trim_end().to_string()
  let lines : Array[String] = text
    .split("\n")
    .map(fn(s) { s.to_string() })
    .collect()
  let result = if lines.length() >= 2 && lines[1] != "" {
    @ports.SelectionResult::{ query: lines[0], selected: Some(lines[1]) }
  } else if lines.length() >= 1 && lines[0] != "" {
    @ports.SelectionResult::{ query: lines[0], selected: None }
  } else {
    @ports.SelectionResult::{ query: "", selected: None }
  }
  Ok(result)
}

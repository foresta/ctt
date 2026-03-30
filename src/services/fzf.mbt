///|
/// Present items in fzf and return the selected item, or None if cancelled.
pub async fn fzf_select(
  items : Array[String],
  prompt~ : String = "Select> "
) -> String? {
  let input = items.join("\n")
  let (read_end, write_end) = @pipe.pipe()
  write_end.write(input)
  write_end.close()
  let (status, output) = @process.collect_stdout(
    "fzf",
    ["--prompt=\{prompt}"],
    stdin=read_end,
  )
  read_end.close()
  if status != 0 {
    return None
  }
  let result = output.text().trim_end().to_string()
  if result == "" {
    None
  } else {
    Some(result)
  }
}

///|
/// Present items in fzf with --print-query, returning the typed query and optional selection.
pub async fn fzf_select_with_query(
  items : Array[String],
  prompt~ : String = "Select> "
) -> (String, String?) {
  let input = items.join("\n")
  let (read_end, write_end) = @pipe.pipe()
  write_end.write(input)
  write_end.close()
  let (_, output) = @process.collect_stdout(
    "fzf",
    ["--print-query", "--prompt=\{prompt}"],
    stdin=read_end,
  )
  read_end.close()
  let text = output.text().trim_end().to_string()
  let lines : Array[String] = text
    .split("\n")
    .map(fn(s) { s.to_string() })
    .collect()
  if lines.length() >= 2 && lines[1] != "" {
    (lines[0], Some(lines[1]))
  } else if lines.length() >= 1 && lines[0] != "" {
    (lines[0], None)
  } else {
    ("", None)
  }
}

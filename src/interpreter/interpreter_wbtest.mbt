///|
/// Test doubles: a renderer that records output and a scripted selector/prompter.
priv struct Recorder {
  lines : Array[String]
  errors : Array[String]
  mut cancelled : Int
  select_answer : String?
  confirm_answer : Bool
  input_answer : String
}

///|
fn recorder(
  select_answer? : String? = None,
  confirm_answer? : Bool = false,
  input_answer? : String = ""
) -> Recorder {
  { lines: [], errors: [], cancelled: 0, select_answer, confirm_answer, input_answer }
}

///|
impl @ports.Renderer for Recorder with print_lines(self, lines) {
  for l in lines {
    self.lines.push(l)
  }
}

///|
impl @ports.Renderer for Recorder with print_table(self, rows) {
  for r in rows {
    self.lines.push(r.join("\t"))
  }
}

///|
impl @ports.Renderer for Recorder with print_error(self, msg) {
  self.errors.push(msg)
}

///|
impl @ports.Renderer for Recorder with print_cancelled(self) {
  self.cancelled = self.cancelled + 1
}

///|
impl @ports.ItemSelector for Recorder with select(self, items~, prompt~) {
  let _ = (items, prompt)
  Ok(self.select_answer)
}

///|
impl @ports.ItemSelector for Recorder with select_with_query(self, items~, prompt~) {
  let _ = (items, prompt)
  Ok({ query: "", selected: self.select_answer })
}

///|
impl @ports.UserPrompter for Recorder with confirm(self, prompt~) {
  let _ = prompt
  Ok(self.confirm_answer)
}

///|
impl @ports.UserPrompter for Recorder with read_line(self, prompt~) {
  let _ = prompt
  Ok(self.input_answer)
}

///|
async fn exec(result : @ports.CommandResult, r : Recorder) -> Bool {
  run(result, r, r, r)
}

async test "Lines / Table / Empty succeed" {
  let r = recorder()
  assert_true(exec(@ports.Lines(["a"]), r))
  assert_true(exec(@ports.Table([["h"], ["v"]]), r))
  assert_true(exec(@ports.Empty, r))
  assert_eq(r.lines, ["a", "h", "v"])
}

async test "Error fails and is rendered" {
  let r = recorder()
  assert_false(exec(@ports.Error("boom"), r))
  assert_eq(r.errors, ["boom"])
}

async test "Sequence and Then fail when any part fails" {
  let r = recorder()
  assert_false(exec(@ports.Sequence([@ports.Lines(["ok"]), @ports.Error("x")]), r))
  assert_true(exec(@ports.Sequence([@ports.Lines(["a"]), @ports.Lines(["b"])]), r))
  assert_false(
    exec(@ports.Then(first=@ports.Lines(["a"]), next=fn() { @ports.Error("x") }), r),
  )
  assert_true(
    exec(@ports.Then(first=@ports.Lines(["a"]), next=fn() { @ports.Empty }), r),
  )
  // A failed first step must not run the continuation.
  let r2 = recorder()
  assert_false(
    exec(@ports.Then(first=@ports.Error("x"), next=fn() { @ports.Lines(["ran"]) }), r2),
  )
  assert_eq(r2.lines, [])
}

async test "Confirm: yes continues, no cancels" {
  let yes = recorder(confirm_answer=true)
  assert_true(exec(@ports.Confirm(prompt="?", on_yes=fn() { @ports.Empty }), yes))
  let no = recorder(confirm_answer=false)
  assert_false(exec(@ports.Confirm(prompt="?", on_yes=fn() { @ports.Empty }), no))
  assert_eq(no.cancelled, 1)
}

async test "Select: empty items is an error, no selection cancels, selection continues" {
  let r = recorder()
  assert_false(exec(@ports.Select(items=[], prompt="p", on_select=fn(_) { @ports.Empty }), r))
  assert_eq(r.errors.length(), 1)
  let none = recorder(select_answer=None)
  assert_false(exec(@ports.Select(items=["a"], prompt="p", on_select=fn(_) { @ports.Empty }), none))
  assert_eq(none.cancelled, 1)
  let picked = recorder(select_answer=Some("a"))
  assert_true(
    exec(
      @ports.Select(items=["a"], prompt="p", on_select=fn(s) { @ports.Lines([s]) }),
      picked,
    ),
  )
  assert_eq(picked.lines, ["a"])
}

async test "Menu and Input" {
  let picked = recorder(select_answer=Some("go"), input_answer="text")
  assert_true(
    exec(@ports.Menu(prompt="p", options=[("go", fn() { @ports.Empty })]), picked),
  )
  assert_true(
    exec(@ports.Input(prompt="p", on_input=fn(s) { @ports.Lines([s]) }), picked),
  )
  assert_eq(picked.lines, ["text"])
  let empty = recorder(input_answer="")
  assert_false(exec(@ports.Input(prompt="p", on_input=fn(_) { @ports.Empty }), empty))
  assert_eq(empty.cancelled, 1)
}

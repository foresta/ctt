///|
fn cmd(args : Array[String]) -> @commands.Command {
  parse(["ctt"] + args).command
}

test "no args / unknown / version" {
  assert_true(cmd([]) is Help)
  assert_true(cmd(["help"]) is Help)
  guard cmd(["opne"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("unknown command 'opne'"))
  assert_true(cmd(["version"]) is Version)
  assert_true(cmd(["--version"]) is Version)
  assert_true(cmd(["-V"]) is Version)
  assert_true(cmd(["ls"]) is Ls)
}

test "new: interactive when no options" {
  guard cmd(["new"]) is New(o) else { fail("expected New") }
  assert_eq(o.repo, None)
  assert_eq(o.branch, None)
  assert_eq(o.base, None)
  assert_eq(o.focus, true)
  assert_eq(o.context, None)
  assert_eq(o.context_file, None)
}

///|
test "new: context sources" {
  guard cmd(["new", "--context", "fix it"]) is New(o) else { fail("expected New") }
  assert_eq(o.context, Some("fix it"))
  guard cmd(["new", "--context-url", "https://example.com/1"]) is New(o) else {
    fail("expected New")
  }
  assert_eq(o.context, Some("https://example.com/1"))
  assert_eq(o.context_file, None)
  guard cmd(["new", "--repo", "r", "--branch", "b", "--context-file", "-"]) is New(o) else {
    fail("expected New")
  }
  assert_eq(o.context, None)
  assert_eq(o.context_file, Some("-"))
  guard cmd(["new", "--context-file", "-"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("--repo and --branch"))
  guard cmd(["new", "--context", "a", "--context-file", "f"]) is Usage(m) else {
    fail("expected Usage")
  }
  assert_true(m.contains("only one of"))
}

test "new: all options, both syntaxes" {
  guard cmd(["new", "--repo", "ctt", "--branch=feat/x", "--base", "main", "--no-focus"])
    is New(o) else {
    fail("expected New")
  }
  assert_eq(o.repo, Some("ctt"))
  assert_eq(o.branch, Some("feat/x"))
  assert_eq(o.base, Some("main"))
  assert_eq(o.focus, false)
}

test "new: usage errors" {
  guard cmd(["new", "--bogus"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("unknown option --bogus"))
  guard cmd(["new", "--repo"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("--repo requires a value"))
  guard cmd(["new", "--base", "main"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("--base requires --branch"))
  guard cmd(["new", "extra"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("positional"))
  guard cmd(["new", "--no-focus=1"]) is Usage(m) else { fail("expected Usage") }
  assert_true(m.contains("does not take a value"))
}

test "open" {
  guard cmd(["open"]) is Open(o) else { fail("expected Open") }
  assert_eq(o.name, None)
  assert_eq(o.focus, true)
  guard cmd(["open", "ctt__main", "--no-focus"]) is Open(o) else {
    fail("expected Open")
  }
  assert_eq(o.name, Some("ctt__main"))
  assert_eq(o.focus, false)
  assert_true(cmd(["open", "a", "b"]) is Usage(_))
}

test "done" {
  guard cmd(["done"]) is Done(o) else { fail("expected Done") }
  assert_eq(o.name, None)
  assert_eq(o.yes, false)
  assert_eq(o.delete_branch, false)
  guard cmd(["done", "ctt__main", "--yes", "--delete-branch"]) is Done(o) else {
    fail("expected Done")
  }
  assert_eq(o.name, Some("ctt__main"))
  assert_eq(o.yes, true)
  assert_eq(o.delete_branch, true)
  assert_true(cmd(["done", "--force"]) is Usage(_))
}

test "status" {
  guard cmd(["status"]) is Status(o) else { fail("expected Status") }
  assert_eq(o.all, false)
  assert_eq(o.name, None)
  guard cmd(["status", "--all"]) is Status(o) else { fail("expected Status") }
  assert_eq(o.all, true)
  guard cmd(["status", "ctt__main"]) is Status(o) else { fail("expected Status") }
  assert_eq(o.name, Some("ctt__main"))
  assert_true(cmd(["status", "--all", "ctt__main"]) is Usage(_))
}

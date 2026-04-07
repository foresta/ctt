///|
// --- parse tests ---

test "parse: empty line returns None" {
  assert_eq(@glob.parse(""), None)
}

test "parse: comment returns None" {
  assert_eq(@glob.parse("# comment"), None)
}

test "parse: simple pattern" {
  let pat = @glob.parse(".DS_Store").unwrap()
  assert_eq(pat.pattern, ".DS_Store")
  assert_eq(pat.negated, false)
  assert_eq(pat.anchored, false)
}

test "parse: negated pattern" {
  let pat = @glob.parse("!important.log").unwrap()
  assert_eq(pat.pattern, "important.log")
  assert_eq(pat.negated, true)
}

test "parse: anchored by leading slash" {
  let pat = @glob.parse("/build").unwrap()
  assert_eq(pat.pattern, "build")
  assert_eq(pat.anchored, true)
}

test "parse: anchored by containing slash" {
  let pat = @glob.parse("build/output").unwrap()
  assert_eq(pat.pattern, "build/output")
  assert_eq(pat.anchored, true)
}

test "parse: trailing slash stripped" {
  let pat = @glob.parse("build/").unwrap()
  assert_eq(pat.pattern, "build")
}

///|
// --- exact match (backward compat) ---

test "matches: exact filename" {
  let pat = @glob.parse(".DS_Store").unwrap()
  assert_true(pat.matches(".DS_Store"))
  assert_false(pat.matches("other"))
}

test "matches: exact filename in subdirectory" {
  let pat = @glob.parse(".DS_Store").unwrap()
  assert_true(pat.matches("sub/.DS_Store"))
}

///|
// --- single * ---

test "matches: star extension" {
  let pat = @glob.parse("*.log").unwrap()
  assert_true(pat.matches("debug.log"))
  assert_true(pat.matches("build/debug.log"))
  assert_false(pat.matches("debug.txt"))
}

test "matches: star does not cross slash" {
  let pat = @glob.parse("build/*").unwrap()
  assert_true(pat.matches("build/output"))
  assert_false(pat.matches("build/sub/output"))
}

///|
// --- ** (doublestar) ---

test "matches: leading doublestar" {
  let pat = @glob.parse("**/node_modules").unwrap()
  assert_true(pat.matches("node_modules"))
  assert_true(pat.matches("packages/app/node_modules"))
  assert_false(pat.matches("node_modules_extra"))
}

test "matches: trailing doublestar" {
  let pat = @glob.parse("foo/**").unwrap()
  assert_true(pat.matches("foo/a"))
  assert_true(pat.matches("foo/a/b"))
  assert_false(pat.matches("bar/a"))
}

test "matches: middle doublestar" {
  let pat = @glob.parse("a/**/b").unwrap()
  assert_true(pat.matches("a/b"))
  assert_true(pat.matches("a/x/b"))
  assert_true(pat.matches("a/x/y/b"))
  assert_false(pat.matches("c/x/b"))
}

///|
// --- ? ---

test "matches: question mark" {
  let pat = @glob.parse("?.txt").unwrap()
  assert_true(pat.matches("a.txt"))
  assert_false(pat.matches("ab.txt"))
}

///|
// --- anchoring ---

test "matches: anchored pattern only matches from root" {
  let pat = @glob.parse("/build").unwrap()
  assert_true(pat.matches("build"))
  assert_false(pat.matches("sub/build"))
}

test "matches: non-anchored matches anywhere" {
  let pat = @glob.parse("build").unwrap()
  assert_true(pat.matches("build"))
  assert_true(pat.matches("sub/build"))
}

///|
// --- negation ---

test "parse: negation flag" {
  let pat = @glob.parse("!important.log").unwrap()
  assert_true(pat.matches("important.log"))
  assert_eq(pat.negated, true)

  let pat2 = @glob.parse("*.log").unwrap()
  assert_eq(pat2.negated, false)
}

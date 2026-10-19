///|
test "quote escapes single quotes" {
  assert_eq(@shell.quote("plain"), "'plain'")
  assert_eq(@shell.quote("it's"), "'it'\\''s'")
  assert_eq(@shell.quote("a b\nc"), "'a b\nc'")
}

///|
test "detached_after wraps the command in a delayed nohup subshell" {
  assert_eq(
    @shell.detached_after(2, "herdr workspace close 'w3'"),
    "nohup sh -c 'sleep 2; herdr workspace close '\\''w3'\\''' >/dev/null 2>&1 &",
  )
}

///|
test "normalize trims and rejects empty or multi-line text" {
  assert_eq(@title.normalize("  fix login redirect \n"), Ok("fix login redirect"))
  assert_true(@title.normalize("   ") is Err(_))
  assert_true(@title.normalize("a\nb") is Err(_))
}

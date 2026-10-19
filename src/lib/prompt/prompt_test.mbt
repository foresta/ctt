///|
test "render_prompt fills every {context}" {
  assert_eq(@prompt.render_prompt("Do: {context}", "fix it"), "Do: fix it")
  assert_eq(@prompt.render_prompt("{context} / {context}", "x"), "x / x")
  assert_eq(@prompt.render_prompt("no placeholder", "x"), "no placeholder")
}

///|
test "expand_prompt with a file substitutes a cat subshell" {
  assert_eq(
    @prompt.expand_prompt("claude {prompt}", Some("/h/.config/ctt/tasks/r__b.md")),
    "claude \"$(cat '/h/.config/ctt/tasks/r__b.md')\"",
  )
  assert_eq(
    @prompt.expand_prompt("claude --continue || claude {prompt}", Some("/p")),
    "claude --continue || claude \"$(cat '/p')\"",
  )
}

///|
test "expand_prompt without a file removes the placeholder" {
  assert_eq(@prompt.expand_prompt("claude {prompt}", None), "claude")
  assert_eq(@prompt.expand_prompt("claude {prompt} --model opus", None), "claude --model opus")
  assert_eq(@prompt.expand_prompt("claude --continue || claude {prompt}", None), "claude --continue || claude")
}

///|
test "expand_prompt without a file keeps quoted arguments intact" {
  assert_eq(
    @prompt.expand_prompt("claude --append-system-prompt 'use  two  spaces' {prompt}", None),
    "claude --append-system-prompt 'use  two  spaces'",
  )
  assert_eq(@prompt.expand_prompt("{prompt}", None), "")
}

///|
test "accepts_prompt" {
  assert_true(@prompt.accepts_prompt("claude {prompt}"))
  assert_false(@prompt.accepts_prompt("claude"))
}

///|
test "expand_prompt leaves commands without the placeholder untouched" {
  assert_eq(@prompt.expand_prompt("claude   --x", None), "claude   --x")
  assert_eq(@prompt.expand_prompt("claude", Some("/p")), "claude")
}

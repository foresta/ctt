///|
test "worktree_name and prompt_path" {
  assert_eq(@domain.worktree_name("ctt", "feat-x"), "ctt__feat-x")
  assert_eq(@domain.prompt_path("/h/.config/ctt", "ctt__feat-x"), "/h/.config/ctt/tasks/ctt__feat-x.md")
  assert_eq(@domain.prompt_path("/h/.config/ctt", "ctt__feat/x"), "/h/.config/ctt/tasks/ctt__feat%2Fx.md")
}

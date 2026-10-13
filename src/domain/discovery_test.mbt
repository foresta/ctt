///|
test "resolve_repo: by name" {
  let repos = ["/w/ctt", "/w/team/api"]
  assert_eq(@domain.resolve_repo(repos, "ctt"), Ok("/w/ctt"))
  assert_eq(@domain.resolve_repo(repos, "api"), Ok("/w/team/api"))
}

test "resolve_repo: by absolute path, trailing slash tolerated" {
  let repos = ["/w/ctt"]
  assert_eq(@domain.resolve_repo(repos, "/w/ctt"), Ok("/w/ctt"))
  assert_eq(@domain.resolve_repo(repos, "/w/ctt/"), Ok("/w/ctt"))
  assert_true(@domain.resolve_repo(repos, "/w/other") is Err(_))
}

test "resolve_repo: not found and ambiguous" {
  let repos = ["/w/a/ctt", "/w/b/ctt"]
  match @domain.resolve_repo(repos, "nope") {
    Err(e) => assert_true(e.contains("not found"))
    Ok(_) => fail("expected Err")
  }
  match @domain.resolve_repo(repos, "ctt") {
    Err(e) => {
      assert_true(e.contains("ambiguous"))
      assert_true(e.contains("/w/a/ctt"))
    }
    Ok(_) => fail("expected Err")
  }
}

///|
/// Tokens of a subcommand's arguments: `--key value` / `--key=value` pairs,
/// bare `--flag`s, and positionals.
priv struct Scanned {
  positionals : Array[String]
  values : Map[String, String]
  flags : Array[String]
}

///|
/// Split `params` into values, flags and positionals. Options not listed in
/// `value_options` or `flag_options` are errors.
fn scan(
  params : Array[String],
  value_options~ : Array[String],
  flag_options~ : Array[String]
) -> Result[Scanned, String] {
  let positionals : Array[String] = []
  let values : Map[String, String] = Map([])
  let flags : Array[String] = []
  let mut i = 0
  while i < params.length() {
    let arg = params[i]
    if arg.has_prefix("--") && arg.length() > 2 {
      let body = arg[2:].to_owned()
      let (key, inline_value) = match body.find("=") {
        Some(idx) => (body[:idx].to_owned(), Some(body[idx + 1:].to_owned()))
        None => (body, None)
      }
      if value_options.contains(key) {
        match inline_value {
          Some(v) => values[key] = v
          None =>
            if i + 1 < params.length() {
              values[key] = params[i + 1]
              i = i + 1
            } else {
              return Err("--\{key} requires a value")
            }
        }
      } else if flag_options.contains(key) {
        if inline_value is Some(_) {
          return Err("--\{key} does not take a value")
        }
        flags.push(key)
      } else {
        return Err("unknown option --\{key}")
      }
    } else {
      positionals.push(arg)
    }
    i = i + 1
  }
  Ok({ positionals, values, flags })
}

///|
/// At most one positional argument (the worktree name).
fn single_name(scanned : Scanned, command : String) -> Result[String?, String] {
  match scanned.positionals.length() {
    0 => Ok(None)
    1 => Ok(Some(scanned.positionals[0]))
    _ =>
      Err(
        "\{command} takes at most one argument: " +
        scanned.positionals.join(" "),
      )
  }
}

///|
fn parse_new(params : Array[String]) -> @commands.Command {
  let s = match
    scan(params, value_options=["repo", "branch", "base"], flag_options=[
      "no-focus",
    ]) {
    Ok(s) => s
    Err(e) => return Usage(e)
  }
  if !s.positionals.is_empty() {
    return Usage(
      "new does not take positional arguments: " + s.positionals.join(" "),
    )
  }
  if s.values.get("base") is Some(_) && s.values.get("branch") is None {
    return Usage("--base requires --branch")
  }
  New({
    repo: s.values.get("repo"),
    branch: s.values.get("branch"),
    base: s.values.get("base"),
    focus: !s.flags.contains("no-focus"),
  })
}

///|
fn parse_open(params : Array[String]) -> @commands.Command {
  let s = match scan(params, value_options=[], flag_options=["no-focus"]) {
    Ok(s) => s
    Err(e) => return Usage(e)
  }
  match single_name(s, "open") {
    Ok(name) => Open({ name, focus: !s.flags.contains("no-focus") })
    Err(e) => Usage(e)
  }
}

///|
fn parse_done(params : Array[String]) -> @commands.Command {
  let s = match
    scan(params, value_options=[], flag_options=["yes", "delete-branch"]) {
    Ok(s) => s
    Err(e) => return Usage(e)
  }
  match single_name(s, "done") {
    Ok(name) =>
      Done({
        name,
        yes: s.flags.contains("yes"),
        delete_branch: s.flags.contains("delete-branch"),
      })
    Err(e) => Usage(e)
  }
}

///|
fn parse_status(params : Array[String]) -> @commands.Command {
  let s = match scan(params, value_options=[], flag_options=["all"]) {
    Ok(s) => s
    Err(e) => return Usage(e)
  }
  let all = s.flags.contains("all")
  match single_name(s, "status") {
    Ok(Some(_)) if all => Usage("status takes either --all or a worktree name")
    Ok(name) => Status({ all, name })
    Err(e) => Usage(e)
  }
}

///|
/// Parse command-line arguments into a `CommandInput`.
/// Returns Help when no subcommand is given and Usage for an unknown one.
pub fn parse(args : Array[String]) -> @commands.CommandInput {
  if args.length() < 2 {
    return { command: Help }
  }
  if args[1] == "--version" || args[1] == "-V" {
    return { command: Version }
  }
  let params : Array[String] = []
  for i = 2; i < args.length(); i = i + 1 {
    params.push(args[i])
  }
  let command : @commands.Command = match args[1] {
    "ls" => Ls
    "open" => parse_open(params)
    "status" => parse_status(params)
    "done" => parse_done(params)
    "new" => parse_new(params)
    "version" => Version
    "help" | "--help" | "-h" => Help
    other => Usage("unknown command '\{other}' (run `ctt help`)")
  }
  { command, }
}

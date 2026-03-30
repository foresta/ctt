///|
pub fn parse(args : Array[String]) -> @commands.CommandInput raise {
  if args.length() < 2 {
    usage()
    raise @builtin.Failure("no command specified")
  }
  let command : @commands.Command = match args[1] {
    "ls" => Ls
    "open" => Open
    "status" => Status
    "done" => Done
    "new" => New
    _ => {
      usage()
      raise @builtin.Failure("unknown command: \{args[1]}")
    }
  }
  let params : Array[String] = []
  for i = 2; i < args.length(); i = i + 1 {
    params.push(args[i])
  }
  @commands.CommandInput::{ command, params }
}

///|
pub fn usage() -> Unit {
  println("Usage: ctt <command>")
  println("")
  println("Commands:")
  println("  new    Create a worktree and launch ClaudeCode")
  println("  ls     List active tasks")
  println("  open   Open a task in the editor")
  println("  status Show task status (--all for all tasks)")
  println("  done   Complete a task and remove its worktree")
}

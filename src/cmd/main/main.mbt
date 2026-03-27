///|
fn usage() -> Unit {
  println("Usage: ctt <command>")
  println("")
  println("Commands:")
  println("  new    Create a worktree and launch ClaudeCode")
  println("  ls     List active tasks")
  println("  open   Open a task in the editor")
  println("  status Show task status (--all for all tasks)")
  println("  done   Complete a task and remove its worktree")
}

///|
async fn main {
  let args = @env.args()
  if args.length() < 2 {
    usage()
    return
  }
  let cmd = args[1]
  try {
    @config.validate()
  } catch {
    err => {
      println("Error: \{err}")
      return
    }
  }
  match cmd {
    "ls" => {
      try {
        @commands.cmd_ls()
      } catch {
        err => println("Error: \{err}")
      }
    }
    "status" => {
      let sub_args : Array[String] = []
      for i = 2; i < args.length(); i = i + 1 {
        sub_args.push(args[i])
      }
      try {
        @commands.cmd_status(sub_args)
      } catch {
        err => println("Error: \{err}")
      }
    }
    "open" => {
      try {
        @commands.cmd_open()
      } catch {
        err => println("Error: \{err}")
      }
    }
    "new" => {
      try {
        @commands.cmd_new()
      } catch {
        err => println("Error: \{err}")
      }
    }
    "done" => {
      try {
        @commands.cmd_done()
      } catch {
        err => println("Error: \{err}")
      }
    }
    _ => usage()
  }
}

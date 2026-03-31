///|
/// Parse command-line arguments into a `CommandInput`.
/// Returns Help command for missing or unknown subcommands.
pub fn parse(args : Array[String]) -> @commands.CommandInput {
  if args.length() < 2 {
    return @commands.CommandInput::{ command: Help, params: [] }
  }
  let command : @commands.Command = match args[1] {
    "ls" => Ls
    "open" => Open
    "status" => Status
    "done" => Done
    "new" => New
    _ => Help
  }
  let params : Array[String] = []
  for i = 2; i < args.length(); i = i + 1 {
    params.push(args[i])
  }
  @commands.CommandInput::{ command, params }
}

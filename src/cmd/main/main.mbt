///|
async fn main {
  let input = try {
    @cli.parse(@env.args())
  } catch {
    _ => return
  }
  try {
    @config.validate()
  } catch {
    err => {
      println("Error: \{err}")
      return
    }
  }
  let command = @commands.dispatch(input)
  try {
    command.run()
  } catch {
    err => println("Error: \{err}")
  }
}

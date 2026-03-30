///|
pub(open) trait UserPrompter {
  async confirm(Self, prompt~ : String) -> Result[Bool, String]
  async read_line(Self, prompt~ : String) -> Result[String, String]
}

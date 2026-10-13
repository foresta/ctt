///|
/// TOML decoding of the config file. This is the only file that depends on the
/// TOML library; everything else works on `RawConfig` / `CttConfig`.

///|
/// Parse `config.toml` text. Unknown keys are ignored; wrong types are errors.
pub fn parse_config_toml(text : String) -> Result[CttConfig, String] {
  let root = @toml.parse(text) catch {
    Failure(msg) => return Err("invalid TOML: " + tidy_toml_error(msg))
    e => return Err("invalid TOML: \{e}")
  }
  guard root is TomlTable(table) else {
    return Err("invalid TOML: top level must be a table")
  }
  let multiplexer = match table.get("multiplexer") {
    None => None
    Some(TomlString(s)) => Some(s)
    Some(_) => return Err("multiplexer must be a string")
  }
  let herdr_agent_command = match table.get("herdr") {
    None => None
    Some(TomlTable(herdr)) =>
      match herdr.get("agent_command") {
        None => None
        Some(TomlString(s)) => Some(s)
        Some(_) => return Err("herdr.agent_command must be a string")
      }
    Some(_) => return Err("herdr must be a table")
  }
  RawConfig::{ multiplexer, herdr_agent_command, }.to_config()
}

///|
/// The TOML library prefixes messages with an internal source location
/// ("parser.mbt:... FAILED: Expected value at ..."); keep only the part after it.
fn tidy_toml_error(msg : String) -> String {
  match msg.find("FAILED: ") {
    Some(idx) => msg[idx + 8:].to_owned()
    None => msg
  }
}

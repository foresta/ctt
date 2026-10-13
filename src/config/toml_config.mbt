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
  let multiplexer = match string_key(table, "multiplexer", prefix="") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let agent = match sub_table(table, "agent") {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let agent_prompt_template = match
    string_key(agent, "prompt_template", prefix="agent.") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let herdr = match sub_table(table, "herdr") {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let herdr_agent_command = match string_key(herdr, "agent_command", prefix="herdr.") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let herdr_agent_resume_command = match
    string_key(herdr, "agent_resume_command", prefix="herdr.") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  RawConfig::{
    multiplexer,
    agent_prompt_template,
    herdr_agent_command,
    herdr_agent_resume_command,
  }.to_config()
}

///|
/// Optional sub-table; an absent table behaves like an empty one.
fn sub_table(
  table : Map[String, @toml.TomlValue],
  key : String
) -> Result[Map[String, @toml.TomlValue], String] {
  match table.get(key) {
    None => Ok(Map([]))
    Some(TomlTable(t)) => Ok(t)
    Some(_) => Err(key + " must be a table")
  }
}

///|
/// Optional string key of a table. `prefix` names the table in error messages.
fn string_key(
  table : Map[String, @toml.TomlValue],
  key : String,
  prefix~ : String
) -> Result[String?, String] {
  match table.get(key) {
    None => Ok(None)
    Some(TomlString(s)) => Ok(Some(s))
    Some(_) => Err(prefix + key + " must be a string")
  }
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

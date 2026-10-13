///|
/// Terminal backend used to open a task workspace.
pub(all) enum Multiplexer {
  Herdr
  Tmux
} derive(Eq, Debug)

///|
pub extend Multiplexer with Eq::{equal, not_equal}

///|
pub extend Multiplexer with @debug.Debug::{to_repr}

///|
/// Settings for the herdr backend.
pub(all) struct HerdrConfig {
  /// Command run in the left pane of each workspace (`--continue` is appended when resuming).
  agent_command : String
} derive(Eq, Debug)

///|
pub extend HerdrConfig with Eq::{equal, not_equal}

///|
pub extend HerdrConfig with @debug.Debug::{to_repr}

///|
/// User configuration loaded from `~/.config/ctt/config.toml`.
pub(all) struct CttConfig {
  multiplexer : Multiplexer
  herdr : HerdrConfig
} derive(Eq, Debug)

///|
pub extend CttConfig with Eq::{equal, not_equal}

///|
pub extend CttConfig with @debug.Debug::{to_repr}

///|
pub const DEFAULT_AGENT_COMMAND : String = "claude"

///|
/// Defaults used when the config file is absent or a key is omitted.
pub fn CttConfig::default() -> CttConfig {
  { multiplexer: Herdr, herdr: { agent_command: DEFAULT_AGENT_COMMAND, }, }
}

///|
/// Values extracted from the config file before validation. `None` means the key was omitted.
/// Keeping this independent of the TOML library lets validation be tested without parsing.
pub(all) struct RawConfig {
  multiplexer : String?
  herdr_agent_command : String?
}

///|
/// Map the `multiplexer` key to a backend.
pub fn multiplexer_from_string(s : String) -> Result[Multiplexer, String] {
  match s {
    "herdr" => Ok(Herdr)
    "tmux" => Ok(Tmux)
    _ => Err("invalid multiplexer \"\{s}\": expected \"herdr\" or \"tmux\"")
  }
}

///|
/// Validate raw values and fill in defaults.
pub fn RawConfig::to_config(self : RawConfig) -> Result[CttConfig, String] {
  let multiplexer = match self.multiplexer {
    None => Herdr
    Some(s) =>
      match multiplexer_from_string(s) {
        Ok(m) => m
        Err(e) => return Err(e)
      }
  }
  let agent_command = match self.herdr_agent_command {
    None => DEFAULT_AGENT_COMMAND
    Some(s) =>
      if s.trim().to_owned() == "" {
        return Err("herdr.agent_command must not be empty")
      } else {
        s
      }
  }
  Ok({ multiplexer, herdr: { agent_command, }, })
}

///|
/// Path of the config file (`$HOME/.config/ctt/config.toml`).
pub fn config_file() -> String {
  @path.Path(config_dir()).join(@path.Path("config.toml")).to_string()
}

///|
/// Load the config file. A missing file yields the defaults; read or parse
/// failures are returned as a message prefixed with the file path.
pub fn load_config() -> Result[CttConfig, String] {
  let path = config_file()
  if !@fs.path_exists(path) {
    return Ok(CttConfig::default())
  }
  let text = @fs.read_file_to_string(path) catch {
    IOError(msg) => return Err("\{path}: failed to read: \{msg}")
  }
  match parse_config_toml(text) {
    Ok(c) => Ok(c)
    Err(e) => Err("\{path}: " + e)
  }
}

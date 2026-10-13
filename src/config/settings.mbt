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
  /// Command run in the left pane when a workspace is created for a new worktree.
  agent_command : String
  /// Command run instead when reopening an existing worktree.
  agent_resume_command : String
} derive(Eq, Debug)

///|
pub extend HerdrConfig with Eq::{equal, not_equal}

///|
pub extend HerdrConfig with @debug.Debug::{to_repr}

///|
/// Settings shared by every backend's agent.
pub(all) struct AgentConfig {
  /// Prompt given to the agent when a task starts with context. `{context}` is
  /// replaced with what was passed on the command line.
  prompt_template : String
} derive(Eq, Debug)

///|
pub extend AgentConfig with Eq::{equal, not_equal}

///|
pub extend AgentConfig with @debug.Debug::{to_repr}

///|
/// User configuration loaded from `~/.config/ctt/config.toml`.
pub(all) struct CttConfig {
  multiplexer : Multiplexer
  agent : AgentConfig
  herdr : HerdrConfig
} derive(Eq, Debug)

///|
pub extend CttConfig with Eq::{equal, not_equal}

///|
pub extend CttConfig with @debug.Debug::{to_repr}

///|
/// `{prompt}` expands to the saved task prompt, or to nothing when there is none.
pub const DEFAULT_AGENT_COMMAND : String = "claude {prompt}"

///|
pub const DEFAULT_PROMPT_TEMPLATE : String = "Start working on this task. Read the context first, then plan before editing.\n\n{context}"

///|
/// Resume command derived from the agent command: resume the previous session,
/// or start a fresh one when the resume fails because there is nothing to
/// resume (`claude --continue` exits non-zero in a directory without a session).
/// The prompt placeholder is kept only on the fresh-session side.
pub fn default_resume_command(agent_command : String) -> String {
  let without_prompt = @prompt.expand_prompt(agent_command, None)
  "\{without_prompt} --continue || \{agent_command}"
}

///|
/// Defaults used when the config file is absent or a key is omitted.
pub fn CttConfig::default() -> CttConfig {
  {
    multiplexer: Herdr,
    agent: { prompt_template: DEFAULT_PROMPT_TEMPLATE },
    herdr: {
      agent_command: DEFAULT_AGENT_COMMAND,
      agent_resume_command: default_resume_command(DEFAULT_AGENT_COMMAND),
    },
  }
}

///|
/// Values extracted from the config file before validation. `None` means the key was omitted.
/// Keeping this independent of the TOML library lets validation be tested without parsing.
pub(all) struct RawConfig {
  multiplexer : String?
  agent_prompt_template : String?
  herdr_agent_command : String?
  herdr_agent_resume_command : String?
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
  let prompt_template = match
    string_or_default(
      self.agent_prompt_template, "agent.prompt_template",
      DEFAULT_PROMPT_TEMPLATE,
    ) {
    Ok(s) =>
      if s.contains(@prompt.CONTEXT_PLACEHOLDER) {
        s
      } else {
        return Err("agent.prompt_template must contain {context}")
      }
    Err(e) => return Err(e)
  }
  let agent_command = match
    string_or_default(
      self.herdr_agent_command, "herdr.agent_command", DEFAULT_AGENT_COMMAND,
    ) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let agent_resume_command = match
    string_or_default(
      self.herdr_agent_resume_command, "herdr.agent_resume_command",
      default_resume_command(agent_command),
    ) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  Ok({
    multiplexer,
    agent: { prompt_template, },
    herdr: { agent_command, agent_resume_command },
  })
}

///|
/// The value when present (it must not be blank), otherwise `default`.
fn string_or_default(
  value : String?,
  key : String,
  default : String
) -> Result[String, String] {
  match value {
    None => Ok(default)
    Some(s) if s.trim().to_owned() == "" => Err(key + " must not be empty")
    Some(s) => Ok(s)
  }
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

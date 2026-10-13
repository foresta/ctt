///|
// --- parse_config_toml ---

test "empty file yields defaults" {
  assert_eq(@config.parse_config_toml(""), Ok(@config.CttConfig::default()))
  assert_eq(@config.CttConfig::default().multiplexer, @config.Herdr)
  assert_eq(@config.CttConfig::default().herdr.agent_command, "claude {prompt}")
  assert_eq(
    @config.CttConfig::default().herdr.agent_resume_command,
    "claude --continue || claude {prompt}",
  )
  assert_true(
    @config.CttConfig::default().agent.prompt_template.contains("{context}"),
  )
}

///|
test "agent.prompt_template" {
  let cfg = @config.parse_config_toml(
    "[agent]\nprompt_template = \"/start {context}\"\n",
  ).unwrap()
  assert_eq(cfg.agent.prompt_template, "/start {context}")
  match @config.parse_config_toml("[agent]\nprompt_template = \"no placeholder\"\n") {
    Err(e) => assert_true(e.contains("must contain {context}"))
    Ok(_) => fail("expected Err")
  }
  match @config.parse_config_toml("agent = 1\n") {
    Err(e) => assert_true(e.contains("agent must be a table"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "default_resume_command keeps {prompt} only on the fresh side" {
  assert_eq(
    @config.default_resume_command("claude --model opus {prompt}"),
    "claude --model opus --continue || claude --model opus {prompt}",
  )
  assert_eq(
    @config.default_resume_command("claude"),
    "claude --continue || claude",
  )
}

///|
test "multiplexer = tmux" {
  let cfg = @config.parse_config_toml("multiplexer = \"tmux\"\n").unwrap()
  assert_eq(cfg.multiplexer, @config.Tmux)
  assert_eq(cfg.herdr.agent_command, "claude {prompt}")
}

///|
test "herdr with custom agent_command" {
  let text =
    #|multiplexer = "herdr"
    #|
    #|[herdr]
    #|agent_command = "claude --model opus"
    #|
  let cfg = @config.parse_config_toml(text).unwrap()
  assert_eq(cfg.multiplexer, @config.Herdr)
  assert_eq(cfg.herdr.agent_command, "claude --model opus")
  // The resume command follows a customized agent command.
  assert_eq(
    cfg.herdr.agent_resume_command,
    "claude --model opus --continue || claude --model opus",
  )
}

///|
test "herdr with custom agent_resume_command" {
  let text =
    #|[herdr]
    #|agent_resume_command = "claude --resume"
    #|
  let cfg = @config.parse_config_toml(text).unwrap()
  assert_eq(cfg.herdr.agent_command, "claude {prompt}")
  assert_eq(cfg.herdr.agent_resume_command, "claude --resume")
  match @config.parse_config_toml("[herdr]\nagent_resume_command = 1\n") {
    Err(e) => assert_true(e.contains("herdr.agent_resume_command"))
    Ok(_) => fail("expected Err")
  }
  match @config.parse_config_toml("[herdr]\nagent_resume_command = \"\"\n") {
    Err(e) => assert_true(e.contains("must not be empty"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "herdr table only defaults multiplexer to herdr" {
  let text =
    #|[herdr]
    #|agent_command = "claude"
    #|
  assert_eq(@config.parse_config_toml(text).unwrap().multiplexer, @config.Herdr)
}

///|
test "comments and unknown keys are ignored" {
  let text =
    #|# comment
    #|multiplexer = "tmux" # trailing comment
    #|future_key = 1
    #|[tmux]
    #|window_prefix = "x"
    #|
  assert_eq(@config.parse_config_toml(text).unwrap().multiplexer, @config.Tmux)
}

///|
test "invalid multiplexer value" {
  match @config.parse_config_toml("multiplexer = \"zellij\"\n") {
    Err(e) => {
      assert_true(e.contains("zellij"))
      assert_true(e.contains("herdr"))
      assert_true(e.contains("tmux"))
    }
    Ok(_) => fail("expected Err")
  }
}

///|
test "multiplexer of wrong type" {
  match @config.parse_config_toml("multiplexer = 1\n") {
    Err(e) => assert_true(e.contains("multiplexer must be a string"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "herdr.agent_command of wrong type" {
  match @config.parse_config_toml("[herdr]\nagent_command = true\n") {
    Err(e) => assert_true(e.contains("herdr.agent_command"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "herdr is not a table" {
  match @config.parse_config_toml("herdr = \"x\"\n") {
    Err(e) => assert_true(e.contains("herdr must be a table"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "empty agent_command is rejected" {
  match @config.parse_config_toml("[herdr]\nagent_command = \"  \"\n") {
    Err(e) => assert_true(e.contains("must not be empty"))
    Ok(_) => fail("expected Err")
  }
}

///|
test "malformed TOML" {
  match @config.parse_config_toml("multiplexer = \n") {
    Err(e) => {
      assert_true(e.contains("invalid TOML"))
      assert_false(e.contains("FAILED"))
    }
    Ok(_) => fail("expected Err")
  }
}

///|
// --- RawConfig / multiplexer_from_string (library independent) ---

test "multiplexer_from_string" {
  assert_eq(@config.multiplexer_from_string("herdr"), Ok(@config.Herdr))
  assert_eq(@config.multiplexer_from_string("tmux"), Ok(@config.Tmux))
  assert_true(@config.multiplexer_from_string("HERDR") is Err(_))
}

///|
test "RawConfig::to_config fills defaults" {
  let raw = @config.RawConfig::{
    multiplexer: None,
    agent_prompt_template: None,
    herdr_agent_command: None,
    herdr_agent_resume_command: None,
  }
  assert_eq(raw.to_config(), Ok(@config.CttConfig::default()))
}

///|
test "RawConfig::to_config keeps explicit values" {
  let raw = @config.RawConfig::{
    multiplexer: Some("tmux"),
    agent_prompt_template: Some("Task: {context}"),
    herdr_agent_command: Some("claude --verbose"),
    herdr_agent_resume_command: Some("claude --verbose --continue"),
  }
  assert_eq(
    raw.to_config(),
    Ok(@config.CttConfig::{
      multiplexer: @config.Tmux,
      agent: @config.AgentConfig::{ prompt_template: "Task: {context}" },
      herdr: @config.HerdrConfig::{
        agent_command: "claude --verbose",
        agent_resume_command: "claude --verbose --continue",
      },
    }),
  )
}

///|
test "config_file ends with config.toml" {
  assert_true(@config.config_file().has_suffix("/.config/ctt/config.toml"))
}

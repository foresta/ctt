///|
/// Pure helpers for the task prompt: filling the user's context into the
/// prompt template and expanding the `{prompt}` placeholder of agent commands.

///|
/// Placeholder in `prompt_template` replaced with the task context.
pub const CONTEXT_PLACEHOLDER : String = "{context}"

///|
/// Placeholder in agent commands replaced with the saved prompt, or removed.
pub const PROMPT_PLACEHOLDER : String = "{prompt}"

///|
/// Fill `{context}` in the template with the task context.
pub fn render_prompt(template : String, context : String) -> String {
  template.replace_all(old=CONTEXT_PLACEHOLDER, new=context)
}

///|
/// Expand `{prompt}` in an agent command. With a prompt file it becomes
/// `"$(cat '<path>')"`, so the pane line stays short and the prompt may
/// contain newlines or quotes. Without one the placeholder is removed and the
/// surrounding whitespace is collapsed.
pub fn expand_prompt(command : String, prompt_file : String?) -> String {
  if !command.contains(PROMPT_PLACEHOLDER) {
    return command
  }
  match prompt_file {
    Some(path) =>
      command.replace_all(
        old=PROMPT_PLACEHOLDER,
        new="\"$(cat " + @shell.quote(path) + ")\"",
      )
    None =>
      // Drop the placeholder with one adjacent space so the rest of the
      // command, including quoted arguments, is left exactly as written.
      command
      .replace_all(old=" " + PROMPT_PLACEHOLDER, new="")
      .replace_all(old=PROMPT_PLACEHOLDER + " ", new="")
      .replace_all(old=PROMPT_PLACEHOLDER, new="")
      .trim()
      .to_owned()
  }
}

///|
/// Whether a command can receive the task prompt.
pub fn accepts_prompt(command : String) -> Bool {
  command.contains(PROMPT_PLACEHOLDER)
}

///|
/// Trait for executable commands. Each command struct implements this to define its behavior.
pub(open) trait Runnable {
  async run(Self) -> CommandResult raise
}

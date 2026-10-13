///|
/// Reports an argument error and fails.
pub(all) struct UsageErrorCommand {
  message : String
}

///|
impl @ports.Runnable for UsageErrorCommand with run(self) {
  @ports.Error(self.message)
}

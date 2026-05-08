///|
pub(all) struct VersionCommand {}

///|
impl @ports.Runnable for VersionCommand with run(self) {
  let _ = self
  @ports.Lines(["ctt \{@version.VERSION}"])
}

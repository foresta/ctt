///|
/// Helpers for building POSIX shell lines that ctt hands to a shell.

///|
/// Quote a string with single quotes so the shell passes it through verbatim.
pub fn quote(s : String) -> String {
  "'" + s.replace_all(old="'", new="'\\''") + "'"
}

///|
/// Seconds between a process exiting and its own workspace or window being
/// closed, so the output and exit status reach the caller first.
pub const CLOSE_DELAY_SECONDS : Int = 2

///|
/// Shell line that runs `command` after `delay_seconds`, detached from the
/// calling process and immune to SIGHUP, so it survives the caller's
/// terminal pane being closed.
pub fn detached_after(delay_seconds : Int, command : String) -> String {
  "nohup sh -c " +
  quote("sleep \{delay_seconds}; " + command) +
  " >/dev/null 2>&1 &"
}

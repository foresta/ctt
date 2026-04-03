///|
/// Port for rendering command output to a display target.
/// Adapters provide console or other implementations.
pub(open) trait Renderer {
  print_lines(Self, lines : Array[String]) -> Unit
  print_table(Self, rows : Array[Array[String]]) -> Unit
  print_error(Self, msg : String) -> Unit
  print_cancelled(Self) -> Unit
}

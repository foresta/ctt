///|
pub(open) trait SessionManager {
  is_active(Self) -> Bool
  async list_windows(Self) -> Result[Array[String], String]
  async create_window(Self, name~ : String, cwd~ : String, command~ : String) -> Result[Unit, String]
  async kill_window(Self, name~ : String) -> Result[Unit, String]
}

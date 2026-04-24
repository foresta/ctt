///|
/// Port for filesystem operations including directory listing, path checks,
/// directory creation, symlink creation, and file reading.
pub(open) trait FileSystem {
  read_dir(Self, path~ : String) -> Result[Array[String], String]
  path_exists(Self, path~ : String) -> Bool
  is_dir(Self, path~ : String) -> Result[Bool, String]
  create_dir(Self, path~ : String) -> Result[Unit, String]
  async create_symlink(Self, src~ : String, dst~ : String) -> Result[Unit, String]
  read_file_to_string(Self, path~ : String) -> Result[String, String]
  async find_dirs(Self, path~ : String, name~ : String, max_depth~ : Int) -> Result[Array[String], String]
}

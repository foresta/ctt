///|
pub(open) trait FileSystem {
  read_dir(Self, path~ : String) -> Result[Array[String], String]
  path_exists(Self, path~ : String) -> Bool
  is_dir(Self, path~ : String) -> Result[Bool, String]
  create_dir(Self, path~ : String) -> Result[Unit, String]
  async create_symlink(Self, src~ : String, dst~ : String) -> Result[Unit, String]
  read_file_to_string(Self, path~ : String) -> Result[String, String]
}

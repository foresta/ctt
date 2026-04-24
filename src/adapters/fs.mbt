///|
/// Adapter that implements the FileSystem port using OS-level file operations.
pub(all) struct OsFileSystem {}

///|
/// List entries in the given directory.
impl @ports.FileSystem for OsFileSystem with read_dir(self, path~) {
  let _ = self
  try {
    Ok(@xfs.read_dir(path))
  } catch {
    err => Err(err.to_string())
  }
}

///|
/// Check whether a path exists on the filesystem.
impl @ports.FileSystem for OsFileSystem with path_exists(self, path~) {
  let _ = self
  @xfs.path_exists(path)
}

///|
/// Check whether the given path is a directory.
impl @ports.FileSystem for OsFileSystem with is_dir(self, path~) {
  let _ = self
  try {
    Ok(@xfs.is_dir(path))
  } catch {
    err => Err(err.to_string())
  }
}

///|
/// Create a directory at the given path.
impl @ports.FileSystem for OsFileSystem with create_dir(self, path~) {
  let _ = self
  try {
    @xfs.create_dir(path)
    Ok(())
  } catch {
    err => Err(err.to_string())
  }
}

///|
/// Create a symbolic link from src to dst.
impl @ports.FileSystem for OsFileSystem with create_symlink(self, src~, dst~) {
  let _ = self
  let (status, output) = @proc.exec_cmd("ln", ["-s", src, dst])
  if status != 0 {
    return Err("symlink failed: " + output.trim_end().to_string())
  }
  Ok(())
}

///|
/// Read the entire contents of a file as a string.
impl @ports.FileSystem for OsFileSystem with read_file_to_string(self, path~) {
  let _ = self
  try {
    Ok(@xfs.read_file_to_string(path))
  } catch {
    err => Err(err.to_string())
  }
}

///|
/// Find directories matching a name pattern up to max_depth.
impl @ports.FileSystem for OsFileSystem with find_dirs(self, path~, name~, max_depth~) {
  let _ = self
  let (status, output) = @proc.exec_cmd(
    "find",
    [path, "-maxdepth", max_depth.to_string(), "-type", "d", "-name", name, "-prune"],
  )
  if status != 0 {
    return Err("find failed")
  }
  let dirs : Array[String] = output
    .trim_end()
    .to_string()
    .split("\n")
    .filter(fn(s) { s.length() > 0 })
    .map(fn(s) { s.to_string() })
    .collect()
  Ok(dirs)
}

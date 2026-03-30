///|
pub(all) struct OsFileSystem {}

///|
impl @ports.FileSystem for OsFileSystem with read_dir(self, path~) {
  let _ = self
  try {
    Ok(@xfs.read_dir(path))
  } catch {
    err => Err(err.to_string())
  }
}

///|
impl @ports.FileSystem for OsFileSystem with path_exists(self, path~) {
  let _ = self
  @xfs.path_exists(path)
}

///|
impl @ports.FileSystem for OsFileSystem with is_dir(self, path~) {
  let _ = self
  try {
    Ok(@xfs.is_dir(path))
  } catch {
    err => Err(err.to_string())
  }
}

///|
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
impl @ports.FileSystem for OsFileSystem with create_symlink(self, src~, dst~) {
  let _ = self
  let (status, output) = @process.collect_output_merged("ln", ["-s", src, dst])
  if status != 0 {
    return Err("symlink failed: " + output.text().trim_end().to_string())
  }
  Ok(())
}

///|
impl @ports.FileSystem for OsFileSystem with read_file_to_string(self, path~) {
  let _ = self
  try {
    Ok(@xfs.read_file_to_string(path))
  } catch {
    err => Err(err.to_string())
  }
}

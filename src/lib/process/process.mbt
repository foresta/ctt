///|
/// Wrapper around @async_process.collect_output_merged that returns decoded String
/// instead of raw &Data. Uses lossy UTF-8 decoding to avoid Malformed errors.
pub async fn exec_cmd(
  cmd : String,
  args : Array[String],
  cwd~ : String = "",
  stdin? : &@async_process.ProcessInput
) -> (Int, String) {
  let (status, output) = match (cwd, stdin) {
    ("", None) => @async_process.collect_output_merged(cmd, args)
    ("", Some(s)) => @async_process.collect_output_merged(cmd, args, stdin=s)
    (d, None) => @async_process.collect_output_merged(cmd, args, cwd=d)
    (d, Some(s)) => @async_process.collect_output_merged(cmd, args, cwd=d, stdin=s)
  }
  (status, @utf8.decode_lossy(output.binary()[:]))
}

///|
/// Wrapper around @async_process.collect_stdout that returns decoded String
/// instead of raw &Data. Uses lossy UTF-8 decoding to avoid Malformed errors.
pub async fn exec_cmd_stdout(
  cmd : String,
  args : Array[String],
  stdin? : &@async_process.ProcessInput
) -> (Int, String) {
  let (status, output) = match stdin {
    None => @async_process.collect_stdout(cmd, args)
    Some(s) => @async_process.collect_stdout(cmd, args, stdin=s)
  }
  (status, @utf8.decode_lossy(output.binary()[:]))
}

///|
/// Wrapper around @process.collect_output_merged that returns decoded String
/// instead of raw &Data. Uses lossy UTF-8 decoding to avoid Malformed errors.
async fn exec_cmd(
  cmd : String,
  args : Array[String],
  cwd~ : String = "",
  stdin? : &@process.ProcessInput
) -> (Int, String) {
  let (status, output) = match (cwd, stdin) {
    ("", None) => @process.collect_output_merged(cmd, args)
    ("", Some(s)) => @process.collect_output_merged(cmd, args, stdin=s)
    (d, None) => @process.collect_output_merged(cmd, args, cwd=d)
    (d, Some(s)) => @process.collect_output_merged(cmd, args, cwd=d, stdin=s)
  }
  (status, @utf8.decode_lossy(output.binary()[:]))
}

///|
/// Wrapper around @process.collect_stdout that returns decoded String
/// instead of raw &Data. Uses lossy UTF-8 decoding to avoid Malformed errors.
async fn exec_cmd_stdout(
  cmd : String,
  args : Array[String],
  stdin? : &@process.ProcessInput
) -> (Int, String) {
  let (status, output) = match stdin {
    None => @process.collect_stdout(cmd, args)
    Some(s) => @process.collect_stdout(cmd, args, stdin=s)
  }
  (status, @utf8.decode_lossy(output.binary()[:]))
}

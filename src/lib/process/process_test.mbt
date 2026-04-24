///|
test "decode_lossy handles valid UTF-8" {
  let bytes : Bytes = @utf8.encode("hello world")
  let result = @utf8.decode_lossy(bytes[:])
  inspect(result, content="hello world")
}

///|
test "decode_lossy handles invalid UTF-8 without panic" {
  // 0xFF is invalid in UTF-8
  let bytes = Bytes::from_array([0xFF, 0x68, 0x65, 0x6C, 0x6C, 0x6F])
  // Should succeed without raising; invalid bytes replaced with U+FFFD
  let result = @utf8.decode_lossy(bytes[:])
  assert_true(result.contains("hello"))
}

///|
test "decode_lossy handles mixed valid and invalid bytes" {
  // "main" + newline + 0xC0 (invalid) + newline + "feature"
  let bytes = Bytes::from_array(
    [0x6D, 0x61, 0x69, 0x6E, 0x0A, 0xC0, 0x0A, 0x66, 0x65, 0x61, 0x74, 0x75, 0x72, 0x65],
  )
  // Should succeed without raising
  let result = @utf8.decode_lossy(bytes[:])
  assert_true(result.contains("main"))
  assert_true(result.contains("feature"))
}

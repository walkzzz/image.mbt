///|
test "testgen-drive: VP8 关键帧零分区解码" {
  let bytes = @testgen.build_vp8_key_frame(16, 16, first_part_size=64)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 16)
    assert_eq(img.height, 16)
    assert_eq(img.channels, 3)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 帧内预测（bool 编码 is_intra=1）" {
  let bytes = @testgen.build_vp8_intra_frame(16, 16)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 16)
    assert_eq(img.height, 16)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("intra error: " + msg)
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 帧内多模式（8 字节 1 位）" {
  let bytes = @testgen.build_vp8_intra_frame(16, 16, ones=8)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 16)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("intra8 error: " + msg)
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 帧内 32x32（4 宏块）" {
  let bytes = @testgen.build_vp8_intra_frame(32, 32, ones=4)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 32)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("intra32 error: " + msg)
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 帧内 16 字节 1 位（高量化/滤波路径）" {
  let bytes = @testgen.build_vp8_intra_frame(16, 16, ones=16)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.height, 16)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("intra16 error: " + msg)
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 帧内 64x64（16 宏块）" {
  let bytes = @testgen.build_vp8_intra_frame(64, 64, ones=4)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 64)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("intra64 error: " + msg)
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: VP8 模式化首分区（4 种字节模式）" {
  let patterns : Array[Int32] = [170, 85, 240, 15]
  for bv in patterns {
    let bytes = @testgen.build_vp8_pattern_frame(16, 16, byte_val=bv, size=32)
    try {
      let img = @codec.decode_vp8_frame(bytes, 0)
      assert_eq(img.width, 16)
    } catch {
      _ => assert_true(true)
    }
  }
}

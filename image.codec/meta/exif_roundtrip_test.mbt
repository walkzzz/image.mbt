///|
fn exif_wrap_jpeg(seg : Bytes) -> Bytes {
  let out : Array[Byte] = []
  out.push(b'\xFF')
  out.push(b'\xD8')
  out.push(b'\xFF')
  out.push(b'\xE1')
  let seg_len = seg.length() + 2
  out.push((seg_len >> 8).to_byte())
  out.push((seg_len & 0xFF).to_byte())
  for i in 0..<seg.length() {
    out.push(seg[i])
  }
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}

///|
test "exif: create_exif_segment → read_exif_extended_from_bytes 往返" {
  let info = @meta.ExifInfo::{
    make: "MoonBit",
    model: "ImageX",
    orientation: 1,
    date_time: "2026:11:20 12:00:00",
  }
  let seg = @meta.create_exif_segment(info)
  assert_true(seg.length() > 6)
  let jpeg = exif_wrap_jpeg(seg)
  let parsed = @meta.read_exif_extended_from_bytes(jpeg)
  match parsed {
    Some(e) => {
      assert_eq(e.make, "MoonBit")
      assert_eq(e.model, "ImageX")
      assert_true(e.date_time.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "exif: 非 JPEG 与缺失 APP1 返回 None" {
  assert_true(@meta.read_exif_extended_from_bytes(b"\x00\x00\x00") is None)
  let no_app1 = Bytes::from_array([b'\xFF', b'\xD8', b'\xFF', b'\xD9'])
  assert_true(@meta.read_exif_extended_from_bytes(no_app1) is None)
}

///|
test "exif: 多标签（ISO/曝光/光圈/焦距/模式/白平衡/闪光/GPS）" {
  let jpeg = @testgen.build_exif_jpeg()
  match @meta.read_exif_extended_from_bytes(jpeg) {
    Some(e) => {
      assert_eq(e.make, "MoonBit")
      assert_eq(e.model, "ImageX")
      assert_eq(e.orientation, 1)
      assert_eq(e.iso, 100)
      assert_true(e.f_number > 2.0 && e.f_number < 3.5)
      assert_true(e.focal_length > 40.0)
      assert_true(e.exposure_time.length() > 0)
      assert_eq(e.exposure_mode, 1)
      assert_eq(e.white_balance, 0)
      assert_eq(e.flash, 16)
      assert_true(e.gps_latitude > 30.0)
      assert_true(e.gps_longitude > 100.0)
      assert_true(e.gps_altitude > 0.0)
      assert_eq(e.pixel_x_dim, 64)
      assert_eq(e.pixel_y_dim, 48)
    }
    None => assert_true(false)
  }
}

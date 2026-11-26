// 覆盖率测试（白盒）：imgtool CLI 的分发、参数解析、格式推断、端到端子命令

///|
fn cli_tmp_img(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(((x * 37 + y * 11) % 256).to_byte())
      d.push(((x * 11 + y * 37) % 256).to_byte())
      d.push(((x * 5 + y * 3) % 256).to_byte())
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(d),
  }
}

///|
fn cli_png_bytes() -> Bytes {
  @lib.save_image_with_quality(cli_tmp_img(6, 4), @types.ImageFormat::Png, 90) catch {
    _ => Bytes::from_array([])
  }
}

///|
fn cli_write_png(path : String) -> Unit {
  write_bytes(path, cli_png_bytes()) catch {
    _ => ()
  }
}

///|
fn cli_ok(out : Out) -> Bool {
  match out.get("ok") {
    Some(j) => j.stringify() == "true"
    None => false
  }
}

///|
fn cli_has(out : Out, key : String) -> Bool {
  out.contains(key)
}

///|
fn cli_dispatch(args : Array[String]) -> Out {
  dispatch(args) catch {
    _ => usage()
  }
}

///|
test "clicov: 参数解析" {
  let f = parse_flags(["a.png", "--width", "8", "--flag", "b.png"])
  assert_true(f.positional.length() == 1)
  assert_true(f.positional[0] == "a.png")
  assert_true(f.values.get("width") == Some("8"))
  assert_true(f.values.get("flag") == Some("b.png"))
  assert_true(f.has("flag"))
  assert_true(!f.has("nope"))
  assert_true(f.int("width", 0) == 8)
  assert_true(f.int("missing", 5) == 5)
  // 非数字回退默认
  let g = parse_flags(["--width", "abc"])
  assert_true(g.int("width", 3) == 3)
  // 末尾单独 flag 不吞下一个 flag
  let h2 = parse_flags(["--a", "--b", "1"])
  assert_true(h2.values.get("a") == Some("true"))
  assert_true(h2.values.get("b") == Some("1"))
  assert_true(h2.str("a", "x") == "true")
  assert_true(h2.str("zz", "def") == "def")
  // 浮点
  let fv = parse_flags(["--sigma", "1.5"])
  assert_true(fv.float("sigma", 0.0F) == 1.5F)
  assert_true(fv.float("missing", 2.0F) == 2.0F)
  let fv2 = parse_flags(["--sigma", "oops"])
  assert_true(fv2.float("sigma", 2.0F) == 2.0F)
  // 空参数
  let e = parse_flags([])
  assert_true(e.positional.length() == 0)
}

///|
test "clicov: 格式名与解析" {
  assert_true(format_name(@types.ImageFormat::Png) == "png")
  assert_true(format_name(@types.ImageFormat::Jpeg) == "jpeg")
  assert_true(format_name(@types.ImageFormat::Bmp) == "bmp")
  assert_true(format_name(@types.ImageFormat::Gif) == "gif")
  assert_true(format_name(@types.ImageFormat::Webp) == "webp")
  assert_true(format_name(@types.ImageFormat::Qoi) == "qoi")
  assert_true(format_name(@types.ImageFormat::Pnm) == "pnm")
  assert_true(format_name(@types.ImageFormat::Tga) == "tga")
  assert_true(format_name(@types.ImageFormat::Tiff) == "tiff")
  assert_true(format_name(@types.ImageFormat::Ico) == "ico")
  assert_true(format_name(@types.ImageFormat::Cur) == "cur")
  assert_true(format_name(@types.ImageFormat::Icns) == "icns")
  assert_true(format_name(@types.ImageFormat::Apng) == "apng")
  assert_true(format_name(@types.ImageFormat::Avif) == "avif")
  assert_true(format_name(@types.ImageFormat::Heif) == "heif")
  assert_true(format_name(@types.ImageFormat::JpegXl) == "jpeg-xl")
  // parse_format 全分支
  assert_true(parse_format("png") == @types.ImageFormat::Png)
  assert_true(parse_format("jpeg") == @types.ImageFormat::Jpeg)
  assert_true(parse_format("jpg") == @types.ImageFormat::Jpeg)
  assert_true(parse_format("bmp") == @types.ImageFormat::Bmp)
  assert_true(parse_format("webp") == @types.ImageFormat::Webp)
  assert_true(parse_format("qoi") == @types.ImageFormat::Qoi)
  assert_true(parse_format("pnm") == @types.ImageFormat::Pnm)
  assert_true(parse_format("ppm") == @types.ImageFormat::Pnm)
  assert_true(parse_format("tga") == @types.ImageFormat::Tga)
  assert_true(parse_format("gif") == @types.ImageFormat::Gif)
  // 未知格式报错
  try {
    let _ = parse_format("psd")
    assert_true(false)
  } catch {
    @types.ImageError::Process(_, _) => assert_true(true)
    _ => assert_true(false)
  }
  // 可写格式判定
  assert_true(is_writable_format(@types.ImageFormat::Png))
  assert_true(is_writable_format(@types.ImageFormat::Jpeg))
  assert_true(is_writable_format(@types.ImageFormat::Bmp))
  assert_true(is_writable_format(@types.ImageFormat::Webp))
  assert_true(is_writable_format(@types.ImageFormat::Qoi))
  assert_true(is_writable_format(@types.ImageFormat::Pnm))
  assert_true(is_writable_format(@types.ImageFormat::Tga))
  assert_true(is_writable_format(@types.ImageFormat::Gif))
  assert_true(!is_writable_format(@types.ImageFormat::Tiff))
  assert_true(!is_writable_format(@types.ImageFormat::Ico))
  // 扩展名推断（大小写不敏感）
  assert_true(format_from_ext("a.PNG") == Some(@types.ImageFormat::Png))
  assert_true(format_from_ext("a.jpg") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.jpeg") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.jpe") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.webp") == Some(@types.ImageFormat::Webp))
  assert_true(format_from_ext("a.bmp") == Some(@types.ImageFormat::Bmp))
  assert_true(format_from_ext("a.qoi") == Some(@types.ImageFormat::Qoi))
  assert_true(format_from_ext("a.pnm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.ppm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.pgm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.tga") == Some(@types.ImageFormat::Tga))
  assert_true(format_from_ext("a.gif") == Some(@types.ImageFormat::Gif))
  assert_true(format_from_ext("a.tiff") == None)
  assert_true(format_from_ext("a") == None)
}

///|
test "clicov: 输出格式优先级" {
  let dst = "out.jpg"
  // 显式 --format 优先
  let f1 = parse_flags(["--format", "bmp"])
  assert_true(
    out_format(f1, dst, @types.ImageFormat::Png) == @types.ImageFormat::Bmp,
  )
  // auto 视为未指定 → 按扩展名
  let f2 = parse_flags(["--format", "auto"])
  assert_true(
    out_format(f2, dst, @types.ImageFormat::Png) == @types.ImageFormat::Jpeg,
  )
  // 无 flag → 扩展名
  let f3 = parse_flags([])
  assert_true(
    out_format(f3, dst, @types.ImageFormat::Png) == @types.ImageFormat::Jpeg,
  )
  // 未知扩展名 → 回退
  assert_true(
    out_format(f3, "out.zzz", @types.ImageFormat::Webp) ==
    @types.ImageFormat::Webp,
  )
  // 显式非法格式报错
  let f4 = parse_flags(["--format", "psd"])
  try {
    let _ = out_format(f4, dst, @types.ImageFormat::Png)
    assert_true(false)
  } catch {
    @types.ImageError::Process(_, _) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "clicov: 源格式与内存预算" {
  let png = cli_png_bytes()
  assert_true(writable_format_of(png) == @types.ImageFormat::Png)
  assert_true(src_out_format(png) == @types.ImageFormat::Png)
  // 不可写容器退回 PNG：TIFF 头
  let tiff : Array[Byte] = [b'\x49', b'\x49', b'\x2A', b'\x00']
  assert_true(
    writable_format_of(Bytes::from_array(tiff)) == @types.ImageFormat::Png,
  )
  // 默认上限
  let f0 = parse_flags([])
  let l0 = limits_of(f0)
  assert_true(l0.max_bytes > 0L)
  // mem-budget：8000 字节 → max_pixels = 1000
  let f1 = parse_flags(["--mem-budget", "8000"])
  let l1 = limits_of(f1)
  assert_true(l1.max_bytes == 8000L)
  assert_true(l1.max_pixels == 1000L)
  assert_true(l1.max_ms == l0.max_ms)
  // max-pixels 单独覆盖
  let f2 = parse_flags(["--max-pixels", "4096"])
  let l2 = limits_of(f2)
  assert_true(l2.max_pixels == 4096L)
  assert_true(l2.max_bytes == l0.max_bytes)
  // 两者同时：max-pixels 后应用
  let f3 = parse_flags(["--mem-budget", "16000", "--max-pixels", "128"])
  let l3 = limits_of(f3)
  assert_true(l3.max_bytes == 16000L)
  assert_true(l3.max_pixels == 128L)
  // 非法数字回退
  let f4 = parse_flags(["--mem-budget", "x", "--max-pixels", "y"])
  let l4 = limits_of(f4)
  assert_true(l4.max_bytes == l0.max_bytes)
  assert_true(l4.max_pixels == 0L)
}

///|
test "clicov: 小工具函数" {
  // contains_ascii
  let data = Bytes::from_array([b'\x00', b'A', b'B', b'\x00'])
  assert_true(contains_ascii(data, "AB"))
  assert_true(!contains_ascii(data, "BA"))
  assert_true(!contains_ascii(data, ""))
  assert_true(!contains_ascii(Bytes::from_array([b'\x01']), "AB"))
  // error_json
  let e = @types.ImageError::Process(
    @types.ErrorCode::InvalidArgument,
    "bad arg",
  )
  let j = error_json(e)
  assert_true(!cli_ok(j))
  assert_true(cli_has(j, "code"))
  assert_true(cli_has(j, "message"))
  assert_true(cli_has(j, "hint"))
  // 文本输出
  assert_true(help_text().contains("imgtool"))
  assert_true(help_text().contains("convert"))
  assert_true(version_text().contains(version))
  // usage
  let u = usage()
  assert_true(!cli_ok(u))
  // dispatch 空参数 / 未知子命令 → usage
  let u0 = dispatch([]) catch { _ => usage() }
  assert_true(!cli_ok(u0))
  let u1 = dispatch(["bogus"]) catch { _ => usage() }
  assert_true(!cli_ok(u1))
}

///|

///|
fn cli_fs_writable() -> Bool {
  let p = "_build_cli_fs_probe.bin"
  let wrote = try {
    write_bytes(p, Bytes::from_array([1, 2, 3]))
    true
  } catch {
    _ => false
  }
  if !wrote {
    return false
  }
  let back = Some(read_bytes(p)) catch { _ => None }
  match back {
    Some(b) => b.length() == 3
    None => false
  }
}

///|
test "clicov: 端到端 info / analyze / convert" {
  if !cli_fs_writable() {
    return
  }
  let path = "_build_cli_cov_in.png"
  cli_write_png(path)
  // info
  let info = cli_dispatch(["info", path])
  assert_true(cli_ok(info))
  assert_true(cli_has(info, "width"))
  assert_true(cli_has(info, "height"))
  assert_true(cli_has(info, "format"))
  assert_true(cli_has(info, "bytes"))
  // analyze
  let an = cli_dispatch(["analyze", path])
  assert_true(cli_ok(an))
  assert_true(cli_has(an, "channels"))
  assert_true(cli_has(an, "mean"))
  assert_true(cli_has(an, "std"))
  // convert --dry-run
  let cv = cli_dispatch(["convert", path, "_build_cli_cov_out.png", "--dry-run"])
  assert_true(cli_ok(cv))
  assert_true(cli_has(cv, "format_source"))
  assert_true(cli_has(cv, "bytes"))
  // decode 别名 + 按扩展名推断
  let cv2 = cli_dispatch(["decode", path, "_build_cli_cov_out.bmp", "--dry-run"])
  assert_true(cli_ok(cv2))
  // --best
  let cv3 = cli_dispatch(["convert", path, "x.png", "--best", "--dry-run"])
  assert_true(cli_ok(cv3))
  // --best + --max-bytes
  let cv4 = cli_dispatch([
    "convert", path, "x.png", "--best", "--max-bytes", "1000000", "--dry-run",
  ])
  assert_true(cli_ok(cv4))
  // --best 与 --format 冲突
  let e1 = cli_dispatch(["convert", path, "x.png", "--best", "--format", "png"])
  assert_true(!cli_ok(e1))
  // --max-bytes 缺 --best
  let e2 = cli_dispatch(["convert", path, "x.png", "--max-bytes", "10"])
  assert_true(!cli_ok(e2))
  // quality 越界
  let e3 = cli_dispatch(["convert", path, "x.png", "--quality", "0"])
  assert_true(!cli_ok(e3))
  let e4 = cli_dispatch(["convert", path, "x.png", "--quality", "101"])
  assert_true(!cli_ok(e4))
  // 读不存在的文件
  let e5 = cli_dispatch(["info", "_build_not_exist_zz.png"])
  assert_true(!cli_ok(e5))
}

///|
test "clicov: 端到端 resize / crop / filter / sanitize" {
  if !cli_fs_writable() {
    return
  }
  let path = "_build_cli_cov_in2.png"
  cli_write_png(path)
  // resize cover
  let r1 = cli_dispatch([
    "resize", path, "o.png", "--width", "3", "--height", "2", "--dry-run",
  ])
  assert_true(cli_ok(r1))
  assert_true(cli_has(r1, "mode"))
  // resize contain
  let r2 = cli_dispatch([
    "resize", path, "o.png", "--width", "4", "--height", "4", "--mode", "contain",
    "--dry-run",
  ])
  assert_true(cli_ok(r2))
  // resize 缺尺寸
  let r3 = cli_dispatch(["resize", path, "o.png", "--width", "0", "--dry-run"])
  assert_true(!cli_ok(r3))
  // crop 正常
  let c1 = cli_dispatch([
    "crop", path, "o.png", "--x", "1", "--y", "1", "--width", "2", "--height", "2",
    "--dry-run",
  ])
  assert_true(cli_ok(c1))
  // crop 越界（6x4 上起点 5,3 宽高 4 越界）
  let c2 = cli_dispatch([
    "crop", path, "o.png", "--x", "5", "--y", "3", "--width", "4", "--height", "4",
    "--dry-run",
  ])
  assert_true(!cli_ok(c2))
  // filter box
  let f1 = cli_dispatch([
    "filter", path, "o.png", "--op", "box", "--radius", "1", "--dry-run",
  ])
  assert_true(cli_ok(f1))
  // filter 别名 blur
  let f2 = cli_dispatch(["filter", path, "o.png", "--op", "blur", "--dry-run"])
  assert_true(cli_ok(f2))
  let f3 = cli_dispatch(["filter", path, "o.png", "--op", "gauss", "--dry-run"])
  assert_true(cli_ok(f3))
  // sharpen / median / bilateral / nlm（含别名）
  let f4 = cli_dispatch(["filter", path, "o.png", "--op", "sharp", "--dry-run"])
  assert_true(cli_ok(f4))
  let f5 = cli_dispatch([
    "filter", path, "o.png", "--op", "median", "--ksize", "3", "--dry-run",
  ])
  assert_true(cli_ok(f5))
  let f6 = cli_dispatch([
    "filter", path, "o.png", "--op", "bilateral", "--dry-run",
  ])
  assert_true(cli_ok(f6))
  let f7 = cli_dispatch([
    "filter", path, "o.png", "--op", "denoise", "--dry-run",
  ])
  assert_true(cli_ok(f7))
  // 未知算子 / 负半径 / 非法 ksize
  let e1 = cli_dispatch(["filter", path, "o.png", "--op", "sobel"])
  assert_true(!cli_ok(e1))
  let e2 = cli_dispatch(["filter", path, "o.png", "--radius", "-1"])
  assert_true(!cli_ok(e2))
  let e3 = cli_dispatch([
    "filter", path, "o.png", "--op", "median", "--ksize", "4",
  ])
  assert_true(!cli_ok(e3))
  // normalize_filter_op 直接验证
  assert_true(normalize_filter_op("box") == Some("box"))
  assert_true(normalize_filter_op("gaussian") == Some("gaussian"))
  assert_true(normalize_filter_op("median") == Some("median"))
  assert_true(normalize_filter_op("nlm") == Some("nlm"))
  assert_true(normalize_filter_op("x") == None)
  // sanitize：metadata 政策
  let s1 = cli_dispatch([
    "sanitize", path, "o.png", "--policy", "metadata", "--dry-run",
  ])
  assert_true(cli_ok(s1))
  assert_true(cli_has(s1, "metadata_free"))
  // sanitize：standard + regions
  let s2 = cli_dispatch([
    "sanitize", path, "o.png", "--policy", "standard", "--regions", "0,0,3,2", "--dry-run",
  ])
  assert_true(cli_ok(s2))
  assert_true(cli_has(s2, "regions_redacted"))
  // sanitize：strict + 单数 --region
  let s3 = cli_dispatch([
    "sanitize", path, "o.png", "--policy", "strict", "--region", "0,0,2,2", "--dry-run",
  ])
  assert_true(cli_ok(s3))
  assert_true(cli_has(s3, "blurred"))
  // sanitize 的 quality 走自己的 flags.int，不经过 quality_of（300 由编码器内部处理）
  let e4 = cli_dispatch([
    "sanitize", path, "o.png", "--quality", "300", "--dry-run",
  ])
  assert_true(cli_has(e4, "policy"))
  // emit_bytes：dry-run 返回 false
  let enc = cli_png_bytes()
  assert_true(!emit_bytes("o.png", enc, true))
}

///|
test "clicov: 端到端 bench" {
  if !cli_fs_writable() {
    return
  }
  let path = "_build_cli_cov_in3.png"
  cli_write_png(path)
  let b = cli_dispatch([
    "bench", path, "--iters", "1", "--formats", "png,bogus", "--dry-run",
  ])
  assert_true(cli_ok(b))
  assert_true(cli_has(b, "decode_us"))
  assert_true(cli_has(b, "encode"))
  // 带缩放
  let b2 = cli_dispatch([
    "bench", path, "--iters", "1", "--formats", "png", "--width", "2", "--height",
    "2",
  ])
  assert_true(cli_ok(b2))
  assert_true(cli_has(b2, "resize"))
  // iters 越界
  let e1 = cli_dispatch(["bench", path, "--iters", "0"])
  assert_true(!cli_ok(e1))
  let e2 = cli_dispatch(["bench", path, "--iters", "1001"])
  assert_true(!cli_ok(e2))
  // 格式列表解析
  let fl = parse_format_list(" png , jpeg ,, webp ")
  assert_true(fl.length() == 3)
  assert_true(fl[0] == "png")
  assert_true(fl[2] == "webp")
  assert_true(parse_format_list("").length() == 0)
}

///|
test "clicov: stdout 判定" {
  assert_true(!json_to_stderr([]))
  assert_true(!json_to_stderr(["info"]))
  assert_true(!json_to_stderr(["info", "a.png"]))
  // 非写盘子命令
  assert_true(!json_to_stderr(["analyze", "a.png"]))
  // dst 非 -
  assert_true(!json_to_stderr(["convert", "a.png", "b.png"]))
  // dst 为 - → JSON 走 stderr
  assert_true(json_to_stderr(["convert", "a.png", "-"]))
  // --dry-run 时不走 stderr
  assert_true(!json_to_stderr(["convert", "a.png", "-", "--dry-run"]))
  // 各写盘子命令都能识别
  assert_true(json_to_stderr(["resize", "a.png", "-"]))
  assert_true(json_to_stderr(["crop", "a.png", "-"]))
  assert_true(json_to_stderr(["filter", "a.png", "-"]))
  assert_true(json_to_stderr(["sanitize", "a.png", "-"]))
  assert_true(json_to_stderr(["decode", "a.png", "-"]))
  assert_true(json_to_stderr(["encode", "a.png", "-"]))
}

///|
fn opt_name(o : @types.ImageFormat?) -> String {
  match o {
    Some(f) => format_name(f)
    None => "none"
  }
}

///|
test "format_from_ext 按扩展名推断（大小写不敏感、未知扩展名回 None）" {
  inspect(opt_name(format_from_ext("a.png")), content="png")
  inspect(opt_name(format_from_ext("A.JPG")), content="jpeg")
  inspect(opt_name(format_from_ext("dir/x.tar.gz")), content="none")
  inspect(opt_name(format_from_ext("dir/x.png")), content="png")
  inspect(opt_name(format_from_ext("noext")), content="none")
  inspect(opt_name(format_from_ext("pic.webp")), content="webp")
}

///|
test "out_format 优先级：--format > 输出扩展名 > fallback" {
  let dst_flag = parse_flags(["in.png", "out.jpg", "--format", "webp"])
  inspect(format_name(out_format(dst_flag, "out.jpg", @types.ImageFormat::Png)), content="webp")
  let dst_ext = parse_flags(["in.png", "out.jpg"])
  inspect(format_name(out_format(dst_ext, "out.jpg", @types.ImageFormat::Png)), content="jpeg")
  let dst_none = parse_flags(["in.png", "out"])
  inspect(format_name(out_format(dst_none, "out", @types.ImageFormat::Bmp)), content="bmp")
  let auto = parse_flags(["in.png", "out.webp", "--format", "auto"])
  inspect(format_name(out_format(auto, "out.webp", @types.ImageFormat::Png)), content="webp")
  let unknown_ext = parse_flags(["in.png", "out.zzz"])
  inspect(format_name(out_format(unknown_ext, "out.zzz", @types.ImageFormat::Qoi)), content="qoi")
}

///|
test "help_text / version_text 覆盖关键信息" {
  inspect(help_text().contains("imgtool"), content="true")
  inspect(help_text().contains("--regions"), content="true")
  inspect(help_text().contains("--mem-budget"), content="true")
  inspect(version_text().contains(version), content="true")
  inspect(version.length() > 0, content="true")
}

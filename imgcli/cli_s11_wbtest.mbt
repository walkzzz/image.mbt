///|
/// S11 新增的纯函数测试（不碰文件系统，四目标可跑）。

///|
test "normalize_filter_op 归一与拒绝" {
  inspect(normalize_filter_op("blur") == Some("box"), content="true")
  inspect(normalize_filter_op("box") == Some("box"), content="true")
  inspect(normalize_filter_op("gauss") == Some("gaussian"), content="true")
  inspect(normalize_filter_op("sharp") == Some("sharpen"), content="true")
  inspect(normalize_filter_op("median") == Some("median"), content="true")
  inspect(normalize_filter_op("bilateral") == Some("bilateral"), content="true")
  inspect(normalize_filter_op("denoise") == Some("nlm"), content="true")
  inspect(normalize_filter_op("sepia") is None, content="true")
}

///|
test "parse_format_list 跳过空段与空白" {
  let l = parse_format_list("png, jpeg ,,webp")
  inspect(l.length(), content="3")
  inspect(l[0], content="png")
  inspect(l[1], content="jpeg")
  inspect(l[2], content="webp")
  inspect(parse_format_list(" , ").length(), content="0")
}

///|
test "json_to_stderr 只在真的写二进制到 stdout 时为真" {
  inspect(json_to_stderr(["convert", "in.png", "-"]), content="true")
  inspect(
    json_to_stderr(["convert", "--quality", "80", "in.png", "-"]),
    content="true",
  )
  inspect(json_to_stderr(["sanitize", "in.png", "-"]), content="true")
  // --dry-run 不写二进制，JSON 仍回 stdout
  inspect(
    json_to_stderr(["convert", "in.png", "-", "--dry-run"]),
    content="false",
  )
  // 只读子命令永远不占用 stdout
  inspect(json_to_stderr(["analyze", "-"]), content="false")
  inspect(json_to_stderr(["bench", "in.png"]), content="false")
  // 输出到普通文件
  inspect(json_to_stderr(["filter", "in.png", "out.png"]), content="false")
}

///|
test "Flags::float 解析与回落" {
  let f = parse_flags(["--sigma", "1.5", "--amount", "oops"])
  inspect(f.float("sigma", 0.0F) > 1.4F, content="true")
  inspect(f.float("sigma", 0.0F) < 1.6F, content="true")
  inspect(f.float("amount", 1.0F) > 0.9F, content="true")
  inspect(f.float("missing", 2.5F) > 2.4F, content="true")
}

///|
test "help_text 覆盖 S11 新增子命令与开关" {
  let h = help_text()
  inspect(h.contains("convert"), content="true")
  inspect(h.contains("filter"), content="true")
  inspect(h.contains("bench"), content="true")
  inspect(h.contains("--dry-run"), content="true")
  inspect(h.contains("stdin / stdout"), content="true")
  inspect(h.contains("--best"), content="true")
}

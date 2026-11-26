///|
test "pcov: describe 全操作类型" {
  let ops = [
    @pipeline.Operation::Resize(100, 80),
    @pipeline.Operation::Rotate(45.5),
    @pipeline.Operation::FlipH,
    @pipeline.Operation::FlipV,
    @pipeline.Operation::Grayscale,
    @pipeline.Operation::Invert,
    @pipeline.Operation::Blur(2.5),
    @pipeline.Operation::Sharpen(1.2),
    @pipeline.Operation::Brightness(0.3),
    @pipeline.Operation::Contrast(1.5),
    @pipeline.Operation::Custom("my_op"),
  ]
  let p = @pipeline.pipeline_add_all(@pipeline.pipeline_new(), ops)
  assert_eq(@pipeline.pipeline_len(p), 11)
  let desc = @pipeline.pipeline_describe(p)
  assert_true(desc.contains("resize"))
  assert_true(desc.contains("rotate"))
  assert_true(desc.contains("flip_h"))
  assert_true(desc.contains("flip_v"))
  assert_true(desc.contains("grayscale"))
  assert_true(desc.contains("invert"))
  assert_true(desc.contains("blur"))
  assert_true(desc.contains("sharpen"))
  assert_true(desc.contains("brightness"))
  assert_true(desc.contains("contrast"))
  assert_true(desc.contains("custom(my_op)"))
}

///|
test "pcov: CLI 解析全命令" {
  // 空参数 → Help
  assert_true(
    match @pipeline.cli_parse([]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // convert
  assert_true(
    match @pipeline.cli_parse(["convert", "in.png", "out.jpg"]) {
      @pipeline.CliCommand::Convert(i, o) => i == "in.png" && o == "out.jpg"
      _ => false
    },
  )
  // convert 参数不足
  assert_true(
    match @pipeline.cli_parse(["convert", "in.png"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // resize
  assert_true(
    match @pipeline.cli_parse(["resize", "a.png", "b.png", "120", "90"]) {
      @pipeline.CliCommand::Resize(_i, _o, w, h) => w == 120 && h == 90
      _ => false
    },
  )
  // resize 参数不足
  assert_true(
    match @pipeline.cli_parse(["resize", "a.png", "b.png", "120"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // rotate（含负角度）
  assert_true(
    match @pipeline.cli_parse(["rotate", "a.png", "b.png", "-33.5"]) {
      @pipeline.CliCommand::Rotate(_i, _o, angle) => angle < 0.0
      _ => false
    },
  )
  // rotate 参数不足
  assert_true(
    match @pipeline.cli_parse(["rotate", "a.png", "b.png"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // batch
  assert_true(
    match @pipeline.cli_parse(["batch", "in_dir", "out_dir", "cfg"]) {
      @pipeline.CliCommand::Batch(i, o, c) =>
        i == "in_dir" && o == "out_dir" && c == "cfg"
      _ => false
    },
  )
  // batch 参数不足
  assert_true(
    match @pipeline.cli_parse(["batch", "in_dir", "out_dir"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // info
  assert_true(
    match @pipeline.cli_parse(["info", "a.png"]) {
      @pipeline.CliCommand::Info(p) => p == "a.png"
      _ => false
    },
  )
  // info 参数不足
  assert_true(
    match @pipeline.cli_parse(["info"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // help / 未知命令
  assert_true(
    match @pipeline.cli_parse(["help"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  assert_true(
    match @pipeline.cli_parse(["unknown"]) {
      @pipeline.CliCommand::Help => true
      _ => false
    },
  )
  // 帮助文本
  let help = @pipeline.cli_help()
  assert_true(help.contains("convert"))
  assert_true(help.contains("batch"))
}

///|
test "pcov: 批处理执行与摘要" {
  let cfg = @pipeline.default_batch_config()
  assert_true(cfg.input_format == "auto")
  assert_true(cfg.output_format == "png")
  assert_true(cfg.output_suffix == "_processed")
  assert_true(!cfg.parallel)
  // 空任务列表
  let empty = @pipeline.batch_execute([])
  let s0 = @pipeline.batch_summary(empty)
  assert_true(s0.contains("0/0"))
  // 两个任务
  let p = @pipeline.pipeline_add(
    @pipeline.pipeline_new(),
    @pipeline.Operation::Grayscale,
  )
  let tasks = [
    @pipeline.batch_task("a.png", "a_out.png", p),
    @pipeline.batch_task("b.png", "b_out.png", p),
  ]
  let res = @pipeline.batch_execute(tasks)
  let s1 = @pipeline.batch_summary(res)
  assert_true(s1.contains("2/2"))
  assert_true(s1.contains("0 failed"))
}

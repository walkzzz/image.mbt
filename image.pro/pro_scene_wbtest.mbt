///|
/// 场景入口冒烟：确认再导出链路可用（符号解析 + 调用 + 返回值绑定）。
/// 实现与行为测试仍在原子包内，本测试只证明 pub using 不漏符号。
test "scene/pro: 入口符号可解析且可调用" {
  let _cfg = create_default_stabilization_config()
  assert_true(true)
}

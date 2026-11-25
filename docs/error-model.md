# 错误模型与资源限额

面向"把库放进服务"的一层：坏输入不 panic、不 OOM，错误能被程序识别而不是只能打印。

## 1. 为什么不改 `LoadError`

`LoadError`（`FileIO / UnsupportedFormat / DecodeFailed / EncodeFailed`）已经被 70 个包、数千条测试依赖。S04 不做破坏性重构，而是**新增一层结构化错误**：

- 旧代码继续 `raise LoadError`（零改动、零回归）；
- 新入口（`decode_with_limits` 等）只 `raise ImageError`；
- 两者通过 `image_error_from_load` 投影，消息特征 → 稳定码。

## 2. `ImageError` 与稳定码

```moonbit
pub(all) suberror ImageError {
  Decode(ErrorCode, String)
  Encode(ErrorCode, String)
  Process(ErrorCode, String)
  Budget(ErrorCode, String)
  Cancelled(String)
}
```

`code()` 返回 `<阶段>/<细节>`，跨版本不变，可直接进 JSON 的 `code` 字段：

| code | 含义 | 建议动作 |
|---|---|---|
| `decode/unsupported_format` | 无对应解码器 | 先用 `detect_format` 确认，再转 PNG/JPEG/QOI |
| `decode/invalid_header` | 文件头/尺寸声明非法 | 当坏图拒绝，**不要**按声明预分配 |
| `decode/invalid_dimensions` | 尺寸超出硬上限/溢出 | 当坏图拒绝 |
| `decode/truncated` | 数据被截断 | 丢弃该输入，不要重试同一份数据 |
| `decode/decode_failed` | 其它解码失败 | 记录 code + message 定位 |
| `encode/encode_failed` | 编码失败 | 查通道/尺寸，或换格式（无损用 PNG / WebP-VP8L） |
| `process/invalid_argument` | 参数非法 | 检查尺寸/通道/质量/策略取值 |
| `process/process_failed` | 像素算子失败 | 记录上下文 |
| `budget/limit_bytes` | 输入字节或分配超预算 | 提高 `max_bytes` 或改流式/分块 |
| `budget/limit_pixels` | 像素数超预算 | 提高 `max_pixels`，或先降采样/分区解码 |
| `budget/limit_time` | 耗时超预算 | 缩小任务（降采样、ROI 裁剪）或异步化 |
| `cancelled` | 调用方取消 | 按取消语义返回，**不要**重试 |

`ErrorCode::is_budget()` 用来区分"换大预算可重试"与"直接拒绝"。`image_error_hint(code)` 返回上表的建议文本，可直接回给调用方或 agent。

## 3. 预算

```moonbit
pub(all) struct DecodeLimits {
  max_pixels : Int64   // 默认 5e8（与 MAX_TOTAL_PIXELS 一致）
  max_bytes  : Int64   // 默认 256 MiB
  max_ms     : Int64   // 默认 10 s
}
pub(all) struct AllocBudget {
  max_bytes : Int64    // 默认 512 MiB
}
```

预设：`DecodeLimits::default_limits()` / `strict_limits()`（64 M 像素 + 64 MiB）/ `with_max_pixels(n)`；`AllocBudget::default_budget()`。

**执行顺序（关键）**：字节上限 → 头部声明的像素上限 → 才进解码器。也就是说坏图在**分配内存之前**就被拒绝，这是 100 MB 级"解码炸弹"防不住 OOM 的唯一有效做法（同步纯 MoonBit 实现无法强杀正在跑的循环，`max_ms` 因此只作准入 + 事后判定）。

## 4. 用法

```moonbit
// 不可信输入（上传的图、爬来的图）
let img = @lib.decode_with_limits(bytes, @types.DecodeLimits::strict_limits())
// 只看声明、先验后解
let (w, h) = @lib.check_decode_budget(bytes, @types.DecodeLimits::default_limits())
```

捕获：

```moonbit
try {
  let img = @lib.decode_with_limits(data, limits)
} catch {
  @types.ImageError::Budget(code, msg) => { /* 换预算或拒绝 */ }
  @types.ImageError::Decode(code, msg) => { /* 坏图，记录 */ }
  @types.ImageError::Cancelled(_) => { /* 取消 */ }
  @types.ImageError::Encode(_, _) | @types.ImageError::Process(_, _) => { /* 其它 */ }
}
```

## 5. 已验证的攻击面

| 构造 | 结果 |
|---|---|
| 头部声明 100000×100000 的 QOI（实际 24 字节） | `budget/limit_pixels`，消息含像素数 10000000000 |
| 超过 `max_bytes` 的正常 PNG | `budget/limit_bytes`，未进入解码器 |
| 截断的 JPEG（60 字节） | `decode/*`（`truncated` / `decode_failed` / `invalid_header`） |
| 负宽高 / 0 宽 | `decode/invalid_dimensions` |
| `AllocBudget` 下的 20000²×4 分配 | `budget/limit_bytes` |

回归：`image.codec/lib/error_model_test.mbt`（11 个 test，40+ 断言）。

## 6. 还没做的

- `max_ms` 没有真正的超时中断（需要把解码器改成可让出/可取消的循环，属后续 Sprint）；
- 处理算子接入现状（2026-11-25）：`transform::thumbnail_budgeted` 已在**输出侧**接 `AllocBudget`
  （超预算 `Budget(LimitBytes)`，不分配）；`crop` / `crop_region` / `resize_subsample` 仍是纯 `LoadError` 语义，
  调用方用 `ImageRegion::to_image` 前可自行 `budget.check_image(...)` 预检；其余滤镜尚未逐个接入。

- S05 出口会把 `{code, message, hint}` 原样透传，届时 `ImageError` 成为唯一的对外错误面。

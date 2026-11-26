# 弃用策略与当前清单（S21）

> 起始版本口径：`0.1.2` 的两条取自 `CHANGELOG.md` 的 `[0.1.2]` 实测记录；5 条 `_enhanced` 早于包版本 0.1.0，来自功能版本 v0.5.1 的 Sprint C（见 `docs/changelog.md`），在 0.1.x 里自 0.1.0 起就存在。
>
> 口径：本文件是弃用的**唯一真值**。代码里出现 `#deprecated` 而本表没登记的，`check_deprecations`
> 直接红灯（`check_docs` 的 B12）。反过来本表登记了、代码里已没有的条目，也算漂移。

## 1. 标注规则

1. **必须有替换目标**：`#deprecated("Use <新符号> instead")` 或中文 `请改用 <新符号>`，且新符号在
   同包可见。只标「不推荐」而不给替代路径的，不许合入。
2. **必须带 doc 说明**：被标函数上方的 `///` 文档要写「为什么弃用 + 换成什么 + 差异点」。
3. **跨包调用要加 `skip_current_package=true`**：包内自测还调用旧符号时，不加会把 `--deny-warn` 打红。
4. **场景入口不再导出弃用符号**：`gen_scenes.mjs` 解析 `.mbti` 时跳过 `#deprecated`，所以 4 个场景包
   （`image.doc` / `image.media` / `image.commerce` / `image.pro`）天然不含旧 API。这是有意的：
   新用户从场景入口进，看不到历史包袱。

## 2. 保留窗口

| 阶段 | 动作 |
| --- | --- |
| 标注时 | 保留旧符号，行为不变（允许退化为「内部转调新符号」） |
| 之后至少 **2 个 patch** | 不删、不改签名；文档与 CHANGELOG 记一条 |
| 收口 Sprint（S21、之后的收口） | 复核清单：仍无人依赖的，进入下一阶段候选 |
| 下一次收口之后 | 才允许移除；移除必须出现在 CHANGELOG 的 `### Removed` 并同步本表 |

`0.1.x` 期间**不做移除**：`major.minor` 钉死，移除等同破坏性变更，统一留到 `0.2.0` 批次。
本仓现在 7 条弃用全部处于「保留窗口」内。

## 3. 当前清单（7 条）

| 符号 | 包 | 替换目标 | 弃用理由 | 起始版本 |
| --- | --- | --- | --- | --- |
| `encode_webp_lossy_pure` | `image.codec/codec` | `encode_webp_lossless` | 产物不符合 VP8 规范（GAP-27），仅写 frame tag + DC 值，缺 first partition | 0.1.2 |
| `encode_webp_lossy_full` | `image.codec/codec` | `encode_webp_lossless` | 同上，另一入口 | 0.1.7 |
| `verify_image_source` | `image.domain/forensics` | `verify_image_source_enhanced` | 旧实现缺增强校验项，结论不可用于取证 | 0.1.0（前身 v0.5.1） |
| `understand_document` | `image.vision/ocr` | `understand_document_enhanced` | 旧实现只做版面粗分，不返回结构化字段 | 0.1.0（前身 v0.5.1） |
| `recognize_handwriting` | `image.vision/ocr` | `recognize_handwriting_enhanced` | 旧实现预处理白块检测缺失，识别率不达标（见 known-gaps） | 0.1.0（前身 v0.5.1） |
| `recognize_multilingual` | `image.vision/ocr` | `recognize_multilingual_enhanced` | 旧实现无语言回退链 | 0.1.0（前身 v0.5.1） |
| `calibrate_confidence` | `image.vision/ocr` | `calibrate_confidence_enhanced` | 旧实现只用单一阈值，未做分档校准 | 0.1.0（前身 v0.5.1） |

## 4. 下游怎么处理告警

```moonbit
// 只在确实要调旧 API 的那几行局部抑制，不要整包抑制：
#warnings("-deprecated")
```

新工程请直接用替换目标或场景入口（`@doc` / `@media` / `@commerce` / `@pro`），不会碰到这 7 条。

## 5. 门禁

```powershell
node scripts/check_deprecations.mjs          # 代码 ⇄ 本表 双向比对
node scripts/check_deprecations.mjs --json   # 机读输出
```

比对内容：符号名、所属包、替换目标（从 `#deprecated` 文案里抽 `Use X instead` / `请改用 X`）。
数量不符、符号未登记、替换目标不一致，任一命中即失败。`check_docs` 的 **B12** 会调它。

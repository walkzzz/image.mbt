# 变异测试（S18）

## 目的

覆盖率只能证明"代码被执行过"，不能证明"测试能发现错误"。变异测试向源码注入
人工缺陷，若测试仍然全绿，说明该缺陷对应区域缺少有效断言。

脚本：`scripts/mutation_test.mjs`（Node，无第三方依赖）
复现：在仓库根执行 `node scripts/mutation_test.mjs`，结果写入 `_build/mutation.json`。

## 判定口径

- 每个变异点要求 `find` 文本在目标文件中**唯一命中**（0 次记 `find_missing`，多次记
  `find_ambiguous`，均不参与计分）。
- 变异后跑 `moon test -p <包> --target native`：
  - 输出中没有 `Total tests:` → `compile_error`，不计分；
  - `failed > 0` → `killed`；
  - `failed == 0` → `survived`。
- 无论测试结果如何，`finally` 中写回原文，避免源码被污染。
- 开始前先对涉及的 4 个包各跑一次基线，任一基线不绿即 `exit 2`，避免把"本来就有
  测试失败"误判成 `killed`。
- 门槛：`killed >= 9`（75%），对应路线图 S18「变异得分 ≥70%」。

## 结果（2026-11-26）

| ID | 包 | 变异 | 结果 |
| --- | --- | --- | --- |
| M01 | codec | PNG Paeth 预测选中 `a` 改为 `b` | killed |
| M02 | codec | PNG Average 滤波除数 `/2` 改为 `/3` | killed |
| M03 | codec | PNG Paeth 第三参数 `c` 改为 `b` | killed |
| M04 | codec | BMP 行对齐 `/4*4` 改为 `/2*2` | killed |
| M05 | codec | QOI `OP_RGB` tag `0xFE` 改为 `0xFD` | killed |
| M06 | codec | QOI LUMA 亮度差分基准 `-32` 改为 `-31` | killed |
| M07 | core/types | `check_dims` 允许 `width == 0` | killed |
| M08 | core/types | `check_dims` 维上限 `>` 改为 `>=` | killed |
| M09 | process/color | 灰度 BT.601 除数 `/1000` 改为 `/999` | killed |
| M10 | codec/lib | `encode_apng` 去掉延迟长度校验 | killed |
| M11 | codec/lib | `decode_region` 把 BMP 分派给 QOI 解码器 | killed |
| M12 | codec/lib | `decode_region` 不支持格式的错误文案变化 | survived（预期） |

**得分：11/12 = 91.7%**（门槛 75%）。M12 是纯文案变异（异常类型不变、行为不变），
预期存活，用于验证"变异器不会把无行为差异的改动误算成 killed"；把它剔除后
有效变异点 **11/11 = 100%**。

过程中发现并修补的真实缺口：

- M09 最初存活：`apply_colormap` 的 BT.601 加权和没有落在 `/1000` 与 `/999` 结果
  不同的边界上。新增 `apply_colormap: BT.601 加权和 999 边界` 测试（像素
  `(0, 5, 176)`，加权和 22999，期望灰度 22），把该变异点转为 killed。
- M06 最初选的是 `QOI run length +1 → +2`，但该变异与"写入前有 `pixel_idx <
  pixel_count` 保护"等价（run 超出部分本来就被丢弃），属等价变异体，已换成
  LUMA 差分基准。

## 未覆盖部分

路线图 S18 同时要求"覆盖率 90%"。当前全库行覆盖 35,075/41,889 = 83.7%，距 90%
尚差约 3,000 行，下一步按"每包未覆盖行数 × 补测成本"排序推进，优先处理
`webp_vp8_decode`、`image_stitch`、`tiff_codec` 等大段缺断言的路径。

# 测试报告（TEST_REPORT）

> 实测日期：2026-11-20（moon 工具链 latest，native 本机 + WSL 证明通道）。
> 本文件只记录**可复现**的数字与命令；与 README/known-gaps 的口径由 `scripts/check_docs.mjs` 校验。

## 1. 单元/集成测试矩阵

| 目标 | 命令 | 结果 |
|------|------|------|
| native | `moon test --target native` | **6,585 / 6,585 通过**（2026-11-20 本机实测） |
| wasm-gc | `moon test --target wasm-gc` | 6,585 / 6,585（CI `test` job 实测） |
| js | `moon test --target js` | 6,585 / 6,585（CI `test` job 实测） |
| wasm | `moon test --target wasm` | 6,585 / 6,585（CI `test` job 实测） |
| mp4 白盒 | `moon test mp4 --target native` | 4 / 4（`mp4/mp4_wbtest.mbt`） |

- 测试文件 365 个（364 黑盒 `*_test.mbt` + 1 白盒 `*_wbtest.mbt`）。
- 覆盖 18 格式编解码、三级像素深度、resize、色彩/滤波/边缘/特征/分割/频域、计算摄影、OCR/视频、领域应用。

## 2. 覆盖率

| 指标 | 数值 |
|------|------|
| 可执行行覆盖 | **30,263 / 38,846 = 77.9%**（`moon test --enable-coverage --target native` → `moon coverage report -f summary`） |
| 未覆盖行 | 4,912 行 / 315 文件（`moon coverage analyze`） |
| CI 门槛 | **≥ 77.5%**（`scripts/check_coverage.mjs`，防退化；目标逐版提升至 90%） |

> 历史口径 90.4%（4878/50812）为 2026-11-13 快照；当前实测 77.9%，以本报告为准。README badge 已同步纠正。

## 3. 形式化验证

| 项目 | 结果 |
|------|------|
| 包 | `image.core/safe_math`（`proof_enabled = true`） |
| 命令 | `cd image.core && moon prove`（WSL / Ubuntu，Why3 1.6.0 + Z3 4.8.12） |
| 结果 | **1 of 1 packages proved / 8 goals proved** |
| 已证目标 | `safe_mul_ok`、`clamp_pixel_ok`、`dims_valid_pred`、`int_max_ok`、`int_min_ok`、`valid_index`、`valid_2d_index`、`rotate90_identity` |
| 预留谓词 | 8 条（SMT 超时 / 前端限制，清单见 `safe_math.mbtp` 注释） |

> Windows 本地 `moon prove` 触发工具链 `\\?\` mkdir bug（`Unix.EINVAL`）；统一走 WSL 与 CI `prove` job。

## 4. 变异测试（7 点 / 3 包 / 100% KILLED）

命令：`node scripts/mutation_test.mjs --min-kill=80`（CI `mutation` job 同命令）

| ID | 包 | 变异 | 结果 |
|----|----|------|------|
| M01 | image.core/types | `check_dims` 漏检零宽 | KILLED |
| M02 | image.core/types | `check_dims` 边界 65535 误拒 | KILLED |
| M03 | image.core/types | `check_dims` 漏检零通道 | KILLED |
| M04 | image.codec/util | `resize` 漏检零宽输出 | KILLED |
| M05 | image.codec/util | `resize` 最近邻 x 取整偏移 | KILLED |
| M06 | image.process/segment | `threshold_otsu` 方差比较反转 | KILLED |
| M07 | image.process/segment | `otsu_threshold_value` 通道上限放宽 | KILLED |

- 结果：**7 / 7 KILLED（击杀率 100%）**，报告写入 `mutation-report.json`。
- 过程中发现并修复 3 个测试盲区：resize 零/负尺寸测试的断言被 `try/catch` 吞掉、最近邻下采样只断言尺寸、Otsu 渐变图只断言尺寸。
- 变异点出现 0 次或多次时标记 SKIPPED 并计入总分母，防止"变异点写错也算通过"。

## 5. 性能基准

`moon bench --target native`：根模块 6 项（PNG 1024/4096 编解码、resize），CI `bench` job 回归运行。

## 6. CI 门禁（`.github/workflows/ci.yml`）

| job | 门禁 |
|-----|------|
| `quality` | `moon fmt --check` · 四目标 `check --deny-warn` · `moon info` + `git diff --exit-code -- '*.mbti'` · `check_docs.mjs`（8 断言 + 5 负向自测） |
| `test` | 四目标测试矩阵（native / wasm-gc / js / wasm） |
| `bench` | native 基准 |
| `coverage` | 覆盖率生成 + 77.5% 门槛 + artifact 上传 |
| `mutation` | `mutation_test.mjs --min-kill=80`（7 点 / 3 包） |
| `prove` | Why3 + Z3 + `moon prove` |

## 7. 复现步骤

```bash
moon check --deny-warn --target all
moon test --target all
moon fmt --check
node scripts/check_docs.mjs
moon test --enable-coverage --target native
moon coverage report -f summary
node scripts/check_coverage.mjs coverage-summary.txt --min 77.5
node scripts/mutation_test.mjs --min-kill=80
cd image.core && moon prove   # WSL / Ubuntu
```
# CI/CD 与 GitHub Pages

> 口径：本文件描述**现在生效**的流水线。任何一条与 `.github/workflows/` 不一致，以工作流文件为准并改这里。

## 1. 工作流清单

| 文件 | 触发 | 作业 | 用途 |
| --- | --- | --- | --- |
| `.github/workflows/ci.yml` | push / PR（`dev`、`main`）+ 手动 | `quality` / `test × 4` / `bench` / `coverage` / `mutation` / `prove` / `bindings` | 质量、四后端测试、基准、覆盖率、变异、形式化证明、语言绑定 |

`bindings` 作业的顺序不能改：装 CLI → `moon update` → `moon build --release cmd/imgtool` → Dart 自测 →
`node scripts/build_npm_wasm.mjs --no-test` → `node npm/test.mjs`。**`npm/image.wasm` 是构建产物、不入库**
（255 KB，`.gitignore` 里），漏掉构建这步自测会直接 `ENOENT` 崩（2026-11-27 实测）。
| `.github/workflows/pages.yml` | push `main`（`docs/**`、`playground/**`、README、moon.mod、两个 pages 脚本）+ 手动 | `build` → `deploy` | 构建 playground.js、跑展示页自检、发布 `docs/` 到 Pages |

CI 顶层 `permissions: contents: read`（最小权限）、`concurrency: ci-${{ github.ref }}` + `cancel-in-progress`（同分支新推送取消旧跑）。
Pages 单独拿 `pages: write` / `id-token: write`，`concurrency: pages` 且不取消（部署不可打断）。

> **实证（2026-11-27）**：run [`45869479035`](https://github.com/walkzzz/image.mbt/actions/runs/45869479035) —— 10 个作业全 success（quality / test×4 / bench / coverage / mutation / prove / bindings），Pages run `45866611065` 部署成功。覆盖率门禁在 Linux runner 上同样 ≥90%（与本地 90.07% 同口径）。

> 注意 `concurrency: ci-${{ github.ref }}` + `cancel-in-progress: true`：连续推送时**前一次跑会被 cancelled**，看起来像红但不是失败，最终以最后一次运行为准（2026-11-27 实测）。

## 2. `quality` 作业里的门禁（10 行命令，含 14 条 B 系列断言）

| 步骤 | 命令 | 拦什么 |
| --- | --- | --- |
| 格式 | `moon fmt --check` | 未格式化 |
| 编译 | `moon check --deny-warn --target {native,wasm-gc,js,wasm}` | 四目标任一警告 |
| API 契约 | `moon info` + `git diff --exit-code -- '*.mbti'` | `.mbti` 漂移 |
| 文档真值 | `check_docs --self-test` + `check_docs` | **B1–B14**（见下） |
| API 索引 | `gen_api_index --check` | api_index 漂移 |
| 版本 | `check_version` | 11 个 `moon.mod` / 门面 / CLI / playground / 首页 / 徽章 |
| 导入 | `check_pkg_imports` | `moon.pkg` 冗余导入 |
| 首页数字 | `sync_pages --check` | 首页数字与 README / `docs/coverage.json` 不一致 |
| 展示页 | `check_pages` | 构建 playground.js + 49 项结构/语义/口径检查 |
| 基准集 | `check_benchmarks` | 20 golden + 6 畸形样本 sha256 漂移 |

`check_docs` 的 B 系列：

| 编号 | 内容 |
| --- | --- |
| B1–B2 | README / 导航结构 |
| B3 | 测试数（`7_404` 徽章、`7404 (native)`、架构首行）三处一致 |
| B6 | 包数四值一致（README 徽章 / api_index / capabilities / 架构首行） |
| B9 | `docs/known-gaps.md` 顶行固定格式 |
| B10 | 能力矩阵 = 枚举 + Codec trait（`gen_capabilities`） |
| B11 | 4 个场景入口 = `docs/scenes.json` + `.mbti`（`gen_scenes`） |
| B12 | 弃用清单 = 代码 `#deprecated`（`check_deprecations`） |
| B13 | 相对链接可达 + `docs/*.md` 都在 README 表里 + 10 个子模块有 README（`check_links`） |
| B14 | 源码/文档无 NUL 与控制字符：`image.vision/fieldimg/field_bind_test.mbt` 曾因 5 个字面 `\x00` 被 git 判成二进制（diff/blame/fmt 全失灵），现 1,231 个文本文件逐个字节扫描 |

## 3. 覆盖率口径只有一个真值

`docs/coverage.json`（`coverage@1`）存 `covered / total / percent / threshold`，三处读它：

1. CI `coverage` 作业的门槛（当前 `--min 90`）；
2. README 徽章 `coverage-90.07%25`（B3/B6 一并校验）；
3. Pages 首页的"覆盖率口径"行（`sync_pages.mjs` 写入）。

当前：**38,102 / 42,301 = 90.07%**，分母不排除任何文件（`pub using` 声明行即 0/0，`benchmarks/gen/main.mbt` 0/21 照算）。

## 4. GitHub Pages

- **发布方式**：artifact 部署（不走 Jekyll），产物 = `docs/` 整个目录；首页 `docs/index.html` 是纯静态页 + 浏览器内演示。
- **URL**：`https://walkzzz.github.io/image.mbt/`
- **当前状态（2026-11-27 实测）**：已启用并部署成功，`https://walkzzz.github.io/image.mbt/` 返回 200，`/playground.js` 267,318 字节由当次源码构建。
- **首次开启**：`configure-pages@v5` 的 `enablement: true` 需要 `GITHUB_TOKEN` 有建站权限，实测报 `Resource not accessible by integration`——**首次必须手工开一次**：`gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow`（或 Settings → Pages → Source 选 "GitHub Actions"）。开过之后工作流才能部署。
- **装完 CLI 必须 `moon update`**：CI 每个作业在 `Install MoonBit` 后都有 `Update registry index`（`moon update`）。缺这一步时 `moon check` 会直接报 `Failed to resolve registry dependency moonbitlang/x`，10 个作业同时红（2026-11-27 实测）。

- **发布前自检**：`pages.yml` 先跑 `sync_pages --check` 与 `check_pages`，再上传；`check_pages` 会把 `_build/js/.../playground.js` 拷到 `docs/playground.js`，所以线上包一定是当次源码构建的。
- **演示能做什么**：QR 生成、滤镜（亮度/模糊）、PNG 摘要，全部在浏览器内算（wasm/js 后端），不联网、无 CDN。

## 5. 本地等价命令

```powershell
node scripts/check_release_ready.mjs --skip-slow   # 12 项，约 10 秒
node scripts/check_release_ready.mjs               # 全量（含 moon check / test / pages 构建）
```

`check_release_ready.mjs` 是 `docs/release.md` §九 清单的可执行版本：任一条失败即退出码 1 并打印尾部输出。

## 6. 已知限制（不粉饰）

- `imgtool` 产物命名跨平台不一致：Linux runner 上 `moon build --release cmd/imgtool` 输出的是 **`imgtool.exe`**（不是 `imgtool`）。脚本统一走 `scripts/imgtool_path.mjs` 解析，新增脚本不要自己拼路径。
- `prove` 作业依赖 `why3` + `z3` 的 apt 版本，与本地 WSL 里 8 goals 的版本不完全一致，可能多出/少掉个别 goal。
- `mutation` 作业只跑 7 包 12 个变异点，不是全库变异。
- 最近两次远程 CI 跑（`45528065485` / `45154611067`）失败点都是 `quality` 的 **Format check**，且都发生在 2026-11-23/25 的历史提交上；本地当前 `moon fmt --check` 全绿，推送后重跑即可验证是否只剩这一条。
- CI 不做 `moon publish`：发布是手工不可逆动作，见 `docs/release.md`。

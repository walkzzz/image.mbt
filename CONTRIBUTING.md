# 贡献指南（CONTRIBUTING）

> 欢迎提交 Issue 与 Pull Request。详细代码规范见 [docs/contributing.md](docs/contributing.md)。

## 开发环境

```bash
git clone git@github.com:walkzzz/image.mbt.git
cd image.mbt
moon check --deny-warn --target all
moon test --target native
```

要求 MoonBit 工具链 `latest`（CI 同版本通道）。

## 提交前门禁（必须全绿）

```bash
moon fmt --check
moon check --deny-warn --target all
moon test --target all
moon info && git diff --exit-code -- '*.mbti'
node scripts/check_docs.mjs
node scripts/check_coverage.mjs coverage-summary.txt --min 80.5
```

- `.mbti` 漂移视为契约变更，必须与代码同提交。
- 文档数字（版本 / 测试数 / 包数 / proof / 覆盖率）由 `check_docs.mjs` 校验，禁止手抄漂移。
- 覆盖率不得低于 80.5%；新增代码应自带测试。

## 代码规范

- 纯 MoonBit、零 C FFI、无条件编译（四目标共用）。
- `snake_case` 函数；测试命名 `"函数名: 场景描述"`（唯一）。
- 解码器入口必须调用 `check_dims`，溢出运算使用 `safe_mul` / `safe_mul3`。
- 公共 API 变化必须运行 `moon info` 并检查 `.mbti` diff。

## 提交信息

```
<类型>: <简述>

[可选正文]
```

类型：`feat` / `fix` / `docs` / `refactor` / `test` / `ci` / `chore`。

## 版本与发布

- 版本遵循语义化版本；当前 0.1.0，破坏性变更升 MINOR（0.x 阶段）。
- `moon publish` 由维护者（walkzzz）亲自执行；依赖顺序：core → codec → process → photography/vision → domain。

## 分支与 PR

1. Fork 或从 `dev` 切分支（`feat/...`、`fix/...`）。
2. 保持提交聚焦；一个 PR 解决一件事。
3. PR 模板检查项全部勾选。
4. CI 5 个 job（quality / test / bench / coverage / prove）全绿后合并。
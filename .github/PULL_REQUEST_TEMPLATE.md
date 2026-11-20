## 变更说明

<!-- 这个 PR 做了什么？为什么？关联 Issue: #123 -->

## 变更类型

- [ ] feat（新功能）
- [ ] fix（缺陷修复）
- [ ] docs（文档）
- [ ] refactor（重构）
- [ ] test（测试）
- [ ] ci（CI / 构建）
- [ ] chore（杂项）

## 检查清单（提交前必须全绿）

- [ ] `moon fmt --check` 通过
- [ ] `moon check --deny-warn --target all` 零警告（native / wasm-gc / js / wasm）
- [ ] `moon test --target all` 通过（当前基线 6,580）
- [ ] `moon info` 后 `git diff --exit-code -- '*.mbti'` 无意外漂移
- [ ] `node scripts/check_docs.mjs` 全绿（版本 / 测试数 / 包数 / proof / 覆盖率口径一致）
- [ ] 覆盖率不低于 77.5%（`scripts/check_coverage.mjs`）
- [ ] 新增/修改的解码器入口调用 `check_dims`，溢出路径使用 `safe_mul`
- [ ] 公共 API 变更已同步 `.mbti` 并在描述中说明

## 文档

- [ ] README / CHANGELOG / docs 是否需要同步（若数字或 API 有变化）
- [ ] 是否更新 `docs/known-gaps.md`（新增/关闭缺口）

## 测试证据

<!-- 粘贴关键命令输出（moon test 尾部 / coverage Total 行 / prove Summary） -->

```text

```

## 备注

<!-- 兼容性影响、发布注意事项（moon publish 由维护者执行） -->
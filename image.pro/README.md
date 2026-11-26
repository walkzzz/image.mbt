# walkzzz/image.pro

**专业场景入口（S16）**：除 doc/media/commerce 之外的全部原子包（检测、分割、特征、频域、立体、视觉、摄影、领域算法），给"我要全套"用户一个入口。

```bash
moon add walkzzz/image.pro
```

```moonbit
import "walkzzz/image.pro"
// 之后直接写 @pro.<符号>；符号清单见本包 pkg.generated.mbti
```

## 覆盖范围

包含 `image.process`（detection / edge / feature / filter / frequency / segment / stereo3d 等）、
`image.vision`（aoci / face_recognition / imgir / intelligent_vision / pose_estimation /
scene_understanding / slam 等）、`image.photography`、`image.domain` 的其余原子包。
逐包清单与归属见仓库 `docs/scenes.json`（本包为其中 `image.pro` 一项）。

## 约定

- 本包**只有 `pub using` 再导出，没有实现**；`moon.pkg` 与 `pro_scene.mbt` 由
  `scripts/gen_scenes.mjs` 生成，请勿手改。
- 再导出量最大，因此跨包同名符号按 `docs/scenes.json` 顺序先到先得，冲突清单写在
  `pro_scene.mbt` 顶部注释里——想确认某个符号来自哪个包，请看那里或直接用原子包。
- `#deprecated` 符号不导出。

## 文档

- 场景总览：https://github.com/walkzzz/image.mbt/blob/main/docs/scenes.md
- API 索引（83 包）：https://github.com/walkzzz/image.mbt/blob/main/docs/api_index.md
- 完整签名以本包 `pkg.generated.mbti` 为准。

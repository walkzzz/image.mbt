# Implementation Plan: walkzzz/image.mbt 项目架构全面重构

**Input**: Feature specification from `spec/architecture-refactor/spec.md`

## Summary

将 walkzzz/image.mbt 从 src/ 单体巨石架构重构为根目录下多模块工作空间架构。参考 pinyin 项目的扁平架构模式：子模块直接放根目录（无 modules/ 包裹），去掉 image-* 前缀，image.mbt 仅含文档+version 不做 reexport，用户直接 import 子模块包。核心工作：1) 删除 src/，以根目录下子模块为唯一源码位置；2) 删除 33 个 _advanced 存根包；3) 合并 9 组重叠包，打散 cv_advanced；4) 完成 pure/ 迁移；5) 清理临时文件和过时文档。

## Technical Context

**Language/Version**: MoonBit (latest stable, preferred-target: native)
**Primary Dependencies**: moonbitlang/core (stdlib), moonbitlang/x/math
**Testing**: moon test (四目标: native, wasm-gc, js, wasm), moon check (零 error/warning)
**Target Platform**: native / wasm-gc / js / wasm
**Project Type**: Library (mooncakes.io 发布)
**Constraints**: 纯 MoonBit（零 C FFI），四目标共用代码
**Scale/Scope**: ~1500 公开函数 + ~500 类型，~15000 测试×4 目标

## Project Structure

### Documentation (this feature)

```text
spec/architecture-refactor/
├── spec.md
├── plan.md
└── tasks.md
```

### Target Source Code (重构后)

```text
walkzzz/image.mbt/                           # 根模块（文档门面，无 reexport）
├── moon.mod                             # name = "walkzzz/image.mbt", v0.5.0
├── moon.work                            # members = [".", "core", "codec", "process", "photography", "vision", "domain"]
├── moon.pkg                             # 空（文档入口，不导入子包）
├── image.mbt                            # 文档 + version（像 pinyin.mbt）
├── AGENTS.md
├── README.md
├── LICENSE
│
├── core/                                # Layer 0: 基础类型
│   ├── moon.mod                         # name = "walkzzz/image.core"
│   ├── moon.pkg
│   ├── types/                           # Image, Image16, ImageF, LoadError, AnyImage, Pixel
│   │   ├── moon.pkg
│   │   ├── image.mbt
│   │   ├── image16.mbt
│   │   ├── imagef.mbt
│   │   ├── pixel.mbt
│   │   └── load_error.mbt
│   └── cmd/main/
│
├── codec/                               # Layer 1: 编解码
│   ├── moon.mod                         # name = "walkzzz/image.codec", import = { walkzzz/image.core@0.1.0 }
│   ├── moon.pkg
│   ├── codec/                           # 18 格式编解码
│   │   ├── png/ jpeg/ bmp/ gif/ qoi/ tga/ psd/ hdr/ pnm/
│   │   ├── tiff/ ico/ cur/ icns/ apng/ webp/ avif/ heif/ jpegxl/
│   │   └── detect/
│   ├── lib/                             # 自动格式分派 + 流式解码
│   ├── color/                           # 色彩空间转换
│   ├── meta/                            # EXIF/XMP/IPTC/PNG text
│   ├── barcode/                         # 条码检测
│   ├── util/                            # 配置/resize/zlib
│   └── cmd/main/
│
├── process/                             # Layer 2: 核心图像处理
│   ├── moon.mod                         # name = "walkzzz/image.process", import = { core@0.1.0, codec@0.1.0 }
│   ├── moon.pkg
│   ├── color/                           # 色彩调整/CLAHE/Retinex/阈值
│   ├── filter/                          # 滤波/去噪/锐化 (← 合并 denoise)
│   ├── edge/                            # 边缘检测
│   ├── feature/                         # 特征检测 (← 合并 cv_advanced/feature_*)
│   ├── segment/                         # 分割 (← 合并 segmentation)
│   ├── transform/                       # 几何变换
│   ├── frequency/                       # FFT/DCT/小波
│   ├── enhance/                         # 图像修复/去雾/去噪 (原enhance - HDR移出)
│   ├── detection/                       # 目标检测/跟踪 (← 合并 cv_advanced/detection_*)
│   └── stereo3d/                        # 立体视觉 (← 合并 cv_advanced/stereo_*)
│
├── photography/                         # Layer 3a: 计算摄影
│   ├── moon.mod                         # name = "walkzzz/image.photography", import = { core, codec, process }
│   ├── moon.pkg
│   ├── photo_enhance/                   # 计算摄影 (← 合并 enhance/hdr)
│   ├── superres/                        # 超分辨率
│   ├── fusion/                          # 图像融合 (← 合并 fusion_enhanced)
│   ├── stitch/                          # 图像拼接
│   ├── style_transfer/                  # 风格迁移 (← 合并 stylize)
│   ├── inpainting/                      # 图像修复
│   ├── computational_imaging/           # 计算成像
│   ├── neural_rendering/                # 神经渲染
│   ├── advanced_imaging/                # 高级成像
│   ├── compression/                     # 图像压缩
│   └── quality/                         # 质量评估
│
├── vision/                              # Layer 3b: 计算机视觉
│   ├── moon.mod                         # name = "walkzzz/image.vision", import = { core, codec, process }
│   ├── moon.pkg
│   ├── ocr/                             # OCR 全流程
│   ├── face_recognition/                # 人脸识别
│   ├── pose_estimation/                 # 姿态估计
│   ├── slam/                            # SLAM (← 合并 cv_advanced/slam_*)
│   ├── video/                           # 视频处理
│   ├── scene_understanding/             # 场景理解
│   ├── spatiotemporal/                  # 时空图像
│   ├── vlm_multimodal/                  # 视觉语言模型
│   ├── intelligent_vision/              # 智能视觉
│   ├── fieldimg/                        # 图像场几何
│   ├── imgir/                           # 图像 IR
│   └── aoci/                            # AI 符号索引
│
├── domain/                              # Layer 4: 领域应用
│   ├── moon.mod                         # name = "walkzzz/image.domain", import = { core, codec, process, vision }
│   ├── moon.pkg
│   ├── medical/                         # 医学图像 (← 合并 cv_advanced/medical_*)
│   ├── remote_sensing/                  # 遥感 (← 合并 cv_advanced/remote_sensing_*)
│   ├── encryption/                      # 图像加密
│   ├── watermark/                       # 水印
│   ├── forensics/                       # 图像取证 (← 合并 forensics_enhanced)
│   ├── registration/                    # 图像配准 (← 合并 registration_advanced + fusion配准)
│   ├── retrieval/                       # 图像检索
│   ├── pipeline/                        # 处理管线
│   ├── performance/                     # 性能工具
│   ├── production_utils/                # 生产工具
│   ├── texture/                         # 纹理分析
│   ├── mesh/                            # 网格处理
│   ├── point_cloud/                     # 点云
│   ├── agent_kit/                       # Agent-Kit
│   ├── self_evolve/                     # 自演化 (补关键测试)
│   └── util/                            # 工具函数
│
├── cmd/bench/                           # 基准测试入口
├── docs/                                # 文档
│   ├── architecture.md
│   ├── roadmap.md
│   ├── changelog.md
│   ├── comparison.md
│   ├── api_reference.md
│   ├── skill.md
│   └── references/                     # 移入的参考文档
└── scripts/                             # 构建脚本
```

**Structure Decision**: 参考 pinyin 项目的单模块扁平架构思想，扩展为多模块工作空间。子模块直接放根目录下，无 modules/ 包裹层，无 image-* 前缀。根模块 `walkzzz/image.mbt` 作为文档门面（image.mbt 仅含 version），不做 reexport，用户直接 import 子模块包。

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 6 个子模块而非单模块 | 115+ 包单模块导致根 moon.pkg 导入 65+ 包，20K 行 reexport 不可维护 | 单模块无法在模块级隔离依赖 |
| cv_advanced 打散 | 72 文件单包违反 ≤30 文件原则 | 保持整体使模块失衡 |

## Research & Decisions

### RD-001: 参考架构选型 — pinyin 模式

**Decision**: 参考 pinyin 的扁平架构：子模块直接放根目录，根聚合文件 `image.mbt` 仅含文档+version，不做 reexport

**Rationale**: pinyin 项目证明 MoonBit 库不需要 reexport 层。用户直接 import 子包更清晰，消除 20K 行 reexport.mbt 的维护负担。目录结构更直观。

**Alternatives considered**:
- 保留 reexport → 20K 行不可维护
- per-module reexport + 根包 pub using → 增加复杂度，pinyin 模式更简洁

### RD-002: 子模块放在根目录而非 modules/ 下

**Decision**: 子模块目录（core/, codec/, process/ 等）直接放项目根目录下，不用 modules/ 包裹

**Rationale**: pinyin 的 12 个子包都在根目录下，结构直观。image 虽有更多包，但通过多模块工作空间分区后，根目录只需 6 个子模块目录 + 项目文件，整洁可管理。

### RD-003: 去掉 image-* 前缀

**Decision**: 目录名和 moon.mod 模块名均不使用 image- 前缀：`core/`(walkzzz/image.core), `codec/`(walkzzz/image.codec), `process/`(walkzzz/image.process), `photography/`(walkzzz/image.photography), `vision/`(walkzzz/image.vision), `domain/`(walkzzz/image.domain)

**Rationale**: pinyin 使用 `core/`, `data/`, `convert/` 等简短名称。walkzzz/ 前缀已提供命名空间隔离，无需重复 image- 前缀。import 路径更短：`walkzzz/image.codec/lib` vs `walkzzz/image.mbt-codec/lib`。

### RD-004: 不做 reexport，用户直接 import

**Decision**: image.mbt 仅含 `pub let version` 和文档注释，不重导出任何子模块 API。用户通过 `import "walkzzz/image.process/filter"` + `@filter.gaussian_blur()` 直接访问

**Rationale**: 
- pinyin 模式：`import "walkzzz/pinyin/convert"` + `@convert.to_pinyin()`
- image 同理：`import "walkzzz/image.codec/lib"` + `@lib.load_from_bytes_auto()`
- 消除 20K 行 reexport.mbt，API 变更不再需要同步修改 reexport
- 每个 sub-module 自治，职责清晰

**Breaking change**: 原有的 `@image.gaussian_blur()` 调用模式变为 `@filter.gaussian_blur()`。这是有意的 API 简化。

### RD-005: cv_advanced 打散策略

**Decision**: 72 文件按功能域分散到现有包，4 个 Phase 报告删除，14 个 DL 文件随 _advanced 存根删除

详见 spec.md 中的完整映射表。

### RD-006: 重叠包合并方向

| 源包 | 目标包 | 处理 |
|------|--------|------|
| denoise/ | enhance/ | 非冗余函数迁入 |
| segmentation/ | segment/ | 高级类型迁入，冲突重命名 |
| forensics_enhanced/ | forensics/ | 整合为 tamper_detection.mbt |
| fusion/(旧) | fusion_enhanced/→重命名fusion/ | 简单函数迁入，配准迁出 |
| stylize/ | style_transfer/ | 保留短函数名 |
| registration_advanced/ | registration/ | 含 fusion 配准函数 |
| enhance/hdr | photo_enhance/ | HDR 属于计算摄影 |
| image_encryption_advanced/ | 删除 | 孤立包 |
| image_watermark_advanced/ | 删除 | 孤立包 |
| remote_sensing_advanced/ | 删除 | 孤立包 |

## Data Model

### 模块依赖 DAG

```
core (Layer 0, 零依赖)
  ↑
codec (Layer 1, → core)
  ↑
process (Layer 2, → core + codec)
  ↑          ↑
photography  vision (Layer 3, → core + codec + process)
(3a)           (3b)
                 ↑
             domain (Layer 4, → core + codec + process + vision)
```

### 用户导入方式对比

**旧模式** (reexport):
```moonbit
import "walkzzz/image.mbt"  // 导入根包
@image.gaussian_blur(img, 3.0)
@image.load_from_bytes_auto(bytes)
@image.Image
```

**新模式** (直接 import，参考 pinyin):
```moonbit
import "walkzzz/image.process/filter"   // 按需导入
import "walkzzz/image.codec/lib"
import "walkzzz/image.core/types"

@filter.gaussian_blur(img, 3.0)
@lib.load_from_bytes_auto(bytes)
// Image 类型来自 @types
```

### 包到模块映射表

| 模块 | moon.mod name | 包 | 原位置 |
|------|---------------|-----|--------|
| core | walkzzz/image.core | types | src/types |
| codec | walkzzz/image.codec | codec, lib, color, meta, barcode, util | src/pure/codec + src/lib + src/pure/color + src/meta + src/barcode + src/pure/util |
| process | walkzzz/image.process | color, filter, edge, feature, segment, transform, frequency, enhance, detection, stereo3d | src/color + src/filter + src/denoise + src/edge + src/feature + src/segment + src/segmentation + src/transform + src/frequency + src/enhance + src/detection + src/stereo3d + cv_advanced/feature_* + cv_advanced/detection_* + cv_advanced/stereo_* |
| photography | walkzzz/image.photography | photo_enhance, superres, fusion, stitch, style_transfer, inpainting, computational_imaging, neural_rendering, advanced_imaging, compression, quality | src/photo_enhance + src/superres + src/fusion + src/fusion_enhanced + src/stitch + src/stylize + src/style_transfer + src/inpainting + src/computational_imaging + src/neural_rendering + src/advanced_imaging + src/compression + src/quality |
| vision | walkzzz/image.vision | ocr, face_recognition, pose_estimation, slam, video, scene_understanding, spatiotemporal, vlm_multimodal, intelligent_vision, fieldimg, imgir, aoci | src/ocr + src/face_recognition + src/pose_estimation + src/slam + src/video + src/scene_understanding + src/spatiotemporal + src/vlm_multimodal + src/intelligent_vision + src/fieldimg + src/imgir + src/aoci |
| domain | walkzzz/image.domain | medical, remote_sensing, encryption, watermark, forensics, registration, retrieval, pipeline, performance, production_utils, texture, mesh, point_cloud, agent_kit, self_evolve, util | src/medical + src/remote_sensing + src/encryption + src/watermark + src/forensics + src/forensics_enhanced + src/registration + src/registration_advanced + src/retrieval + src/pipeline + src/performance + src/production_utils + src/texture + src/mesh + src/point_cloud + src/agent_kit + src/self_evolve + src/util |

### 删除清单

| 类别 | 项目 | 数量 |
|------|------|------|
| 存根包 | _advanced 包 | 36 |
| 重叠包 | denoise, segmentation, forensics_enhanced, fusion(旧), stylize, image_encryption_advanced, image_watermark_advanced, remote_sensing_advanced, registration_advanced | 9 |
| 临时文件 | batch*.txt, coverage*.txt, *.py 等 | ~20 |
| 无关文档 | ArcGIS_Pro_*.md, GeoVerse-ARCHITECTURE.md 等 | ~7 |
| 临时测试 | formal_v264, fuzz_v262, fuzz_v263, geoverse_integration | 4 |
| Phase报告 | cv_advanced/phase*_report.mbt | 4 |
| 空包/目录 | examples/, testdata/, coverage_html/, ocr_test/, ocr_test_app/ | 5 |
| src/ 目录 | 整个 src/ 迁移后删除 | 1 |

## Contracts & Interfaces

### 外部接口变更（Breaking Change）

旧模式: `@image.xxx` 统一入口  
新模式: 直接 import 子模块包（参考 pinyin 的 `@convert.to_pinyin()` 模式）

| 旧调用 | 新调用 |
|--------|--------|
| `@image.gaussian_blur(img, 3.0)` | `@filter.gaussian_blur(img, 3.0)` |
| `@image.load_from_bytes_auto(bytes)` | `@lib.load_from_bytes_auto(bytes)` |
| `@image.Image` | `@types.Image` |
| `@image.canny_edge(img)` | `@edge.canny_edge(img)` |

### 内部接口契约

1. **moon.work members**: `[".", "core", "codec", "process", "photography", "vision", "domain"]`
2. **跨模块引用**: `"walkzzz/image.core/types"`, `"walkzzz/image.codec/lib"`, `"walkzzz/image.process/filter"` 等
3. **测试依赖分离**: `import { ... } for "test"` 声明仅测试时依赖
4. **根包不做 reexport**: image.mbt 仅含 `pub let version : String = "0.5.0"` + 文档

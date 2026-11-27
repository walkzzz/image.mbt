///|
/// # walkzzz/image.mbt 图像处理库
///
/// 纯 MoonBit 图像处理库，零 C FFI 依赖。 Pure MoonBit image processing library with zero C FFI dependency.
///
/// 支持 18 种图像格式（PNG/JPEG/BMP/GIF/QOI/TGA/PSD/HDR/PNM/TIFF/ICO/CUR/ICNS/APNG/WebP/AVIF/HEIF/JPEG-XL） Supports 18 image formats (PNG/JPEG/BMP/GIF/QOI/TGA/PSD/HDR/PNM/TIFF/ICO/CUR/ICNS/APNG/WebP/AVIF/HEIF/JPEG-XL)
/// 和多目标编译（native/wasm-gc/js/wasm）。 and multi-target compilation (native/wasm-gc/js/wasm).
///
/// ## 快速入门 Quick Start
///
/// ```moonbit nocheck
/// import "walkzzz/image.codec/lib"
/// import "walkzzz/image.core/types"
///
/// let img = @lib.load_from_bytes_auto(bytes)!
/// let blurred = @lib.gaussian_blur(img, 3.0)
/// ```
///
/// ## 模块结构 Module Structure
///
/// | 模块 Module | 说明 Description | 导入 Import |
/// |-------------|------------------|-------------|
/// | core | 基础类型（Image, Image16, ImageF, LoadError）Base types | `walkzzz/image.core/types` |
/// | codec | 编解码、色彩、元数据、条码 Encoding/decoding, color, metadata, barcode | `walkzzz/image.codec/lib` |
/// | process | 图像处理算法 Image processing algorithms | `walkzzz/image.process/filter` |
/// | photography | 计算摄影 Computational photography | `walkzzz/image.photography/photo_enhance` |
/// | vision | 计算机视觉 Computer vision | `walkzzz/image.vision/ocr` |
/// | domain | 领域应用 Domain-specific applications | `walkzzz/image.domain/medical` |
///
pub let version : String = "0.1.28"

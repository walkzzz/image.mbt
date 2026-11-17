///|
/// # 全局配置状态 Global Configuration State
///
/// 纯 MoonBit 全局配置状态（全目标可用：native/wasm/js）。
/// 用 Ref[Bool]/Ref[Float] 替代 C 端全局状态。
///
/// 纯 MoonBit 全局配置状态（全目标）。使用 Ref[Bool]/Ref[Float] 替代 C 端全局状态。 Pure MoonBit global configuration state (all targets: native/wasm/js).
/// 使用 Ref[Bool]/Ref[Float] 替代 C 端全局状态。 Uses Ref[Bool]/Ref[Float] to replace C-side global state.
///
/// 核心配置 Core configs:
/// - `flip_vertically_on_load_flag` - 加载时垂直翻转 Flip vertically on load
/// - `flip_vertically_on_write_flag` - 保存时垂直翻转 Flip vertically on write
/// - `jpeg_quality` - JPEG 编码质量 JPEG encoding quality
/// - `unpremultiply_alpha_flag` - 解码时去预乘 alpha Demultiply alpha on decode

// 纯 MoonBit 全局配置状态（全目标可用：native/wasm/js）
// 对应 @core 的 C 端全局状态，用 Ref[Bool]/Ref[Float] 替代

///|
let flip_vertically_on_load_flag : Ref[Bool] = Ref(false)

///|
let flip_vertically_on_write_flag : Ref[Bool] = Ref(false)

///|
let unpremultiply_on_load_flag : Ref[Bool] = Ref(false)

///|
let convert_iphone_png_to_rgb_flag : Ref[Bool] = Ref(false)

///|
let hdr_to_ldr_gamma_val : Ref[Float] = Ref(1.0F)

///|
let hdr_to_ldr_scale_val : Ref[Float] = Ref(1.0F)

///|
let ldr_to_hdr_gamma_val : Ref[Float] = Ref(1.0F)

///|
let ldr_to_hdr_scale_val : Ref[Float] = Ref(1.0F)

///|
/// 设置加载时是否垂直翻转（纯 MoonBit，全目标可用）
pub fn set_flip_vertically_on_load_pure(flag : Bool) -> Unit {
  flip_vertically_on_load_flag.val = flag
}

///|
/// 设置写入时是否垂直翻转（纯 MoonBit，全目标可用）
pub fn flip_vertically_on_write_pure(flag : Bool) -> Unit {
  flip_vertically_on_write_flag.val = flag
}

///|
/// 设置加载时是否取消预乘 alpha（纯 MoonBit，全目标可用）
pub fn set_unpremultiply_on_load_pure(flag : Bool) -> Unit {
  unpremultiply_on_load_flag.val = flag
}

///|
/// 设置是否将 iPhone PNG 转换为 RGB（纯 MoonBit，全目标可用）
pub fn convert_iphone_png_to_rgb_pure(flag : Bool) -> Unit {
  convert_iphone_png_to_rgb_flag.val = flag
}

///|
/// 设置 HDR→LDR 转换的 gamma 值（纯 MoonBit，全目标可用）
pub fn hdr_to_ldr_gamma_pure(gamma : Float) -> Unit {
  hdr_to_ldr_gamma_val.val = gamma
}

///|
/// 设置 HDR→LDR 转换的 scale 值（纯 MoonBit，全目标可用）
pub fn hdr_to_ldr_scale_pure(scale : Float) -> Unit {
  hdr_to_ldr_scale_val.val = scale
}

///|
/// 设置 LDR→HDR 转换的 gamma 值（纯 MoonBit，全目标可用）
pub fn ldr_to_hdr_gamma_pure(gamma : Float) -> Unit {
  ldr_to_hdr_gamma_val.val = gamma
}

///|
/// 设置 LDR→HDR 转换的 scale 值（纯 MoonBit，全目标可用）
pub fn ldr_to_hdr_scale_pure(scale : Float) -> Unit {
  ldr_to_hdr_scale_val.val = scale
}

///|
/// 获取加载时是否垂直翻转
pub fn get_flip_vertically_on_load_pure() -> Bool {
  flip_vertically_on_load_flag.val
}

///|
/// 获取写入时是否垂直翻转
pub fn get_flip_vertically_on_write_pure() -> Bool {
  flip_vertically_on_write_flag.val
}

///|
/// 获取加载时是否取消预乘 alpha
pub fn get_unpremultiply_on_load_pure() -> Bool {
  unpremultiply_on_load_flag.val
}

///|
/// 获取是否将 iPhone PNG 转换为 RGB
pub fn get_convert_iphone_png_to_rgb_pure() -> Bool {
  convert_iphone_png_to_rgb_flag.val
}

///|
/// 获取 HDR→LDR gamma
pub fn get_hdr_to_ldr_gamma_pure() -> Float {
  hdr_to_ldr_gamma_val.val
}

///|
/// 获取 HDR→LDR scale
pub fn get_hdr_to_ldr_scale_pure() -> Float {
  hdr_to_ldr_scale_val.val
}

///|
/// 获取 LDR→HDR gamma
pub fn get_ldr_to_hdr_gamma_pure() -> Float {
  ldr_to_hdr_gamma_val.val
}

///|
/// 获取 LDR→HDR scale
pub fn get_ldr_to_hdr_scale_pure() -> Float {
  ldr_to_hdr_scale_val.val
}

///|
/// 文件 IO 的平台分叉：`imgtool` 是 native 工具，但库包本身要保持
/// 四目标可编译（`moon check --target all --deny-warn` 是仓库门禁），
/// 因此 wasm/js 下给出同签名的拒绝实现而不是编译失败。

///|
#cfg(target="native")
pub fn read_bytes(path : String) -> Bytes raise @types.ImageError {
  try {
    @fs.read_file(path)
  } catch {
    _ =>
      raise @types.ImageError::Decode(
        @types.ErrorCode::InvalidArgument,
        "读取文件失败: \{path}",
      )
  }
}

///|
#cfg(target="native")
pub fn write_bytes(path : String, data : Bytes) -> Unit raise @types.ImageError {
  try {
    @fs.write_file(path, data)
  } catch {
    _ =>
      raise @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "写入文件失败: \{path}",
      )
  }
}

///|
#cfg(not(target="native"))
pub fn read_bytes(path : String) -> Bytes raise @types.ImageError {
  ignore(path)
  raise @types.ImageError::Decode(
    @types.ErrorCode::UnsupportedFormat,
    "imgtool 的读写依赖 native 文件系统，请以 native 目标构建",
  )
}

///|
#cfg(not(target="native"))
pub fn write_bytes(path : String, data : Bytes) -> Unit raise @types.ImageError {
  ignore(path)
  ignore(data)
  raise @types.ImageError::Process(
    @types.ErrorCode::UnsupportedFormat,
    "imgtool 的读写依赖 native 文件系统，请以 native 目标构建",
  )
}

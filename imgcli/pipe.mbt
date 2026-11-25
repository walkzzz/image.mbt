///|
/// # 管道输入输出（`-` 约定）
///
/// 约定与 ImageMagick / ffmpeg 一致：路径写 `-` 表示 stdin 或 stdout。
/// 底层能力只在 native 目标存在（见 `stdio_stub.c`）；非 native 目标返回
/// `None` / `false`，由调用方转成 `UnsupportedFormat` 错误，保证四目标同签名。

///|
#cfg(target="native")
extern "C" fn read_stdin_ffi() -> Bytes = "moonbit_imgcli_read_stdin"

///|
#cfg(target="native")
#borrow(data)
extern "C" fn write_stdout_ffi(data : Bytes) -> Unit = "moonbit_imgcli_write_stdout"

///|
/// 读 stdin 全量字节；非 native 目标返回 `None`。
#cfg(target="native")
pub fn read_stdin_bytes() -> Bytes? {
  Some(read_stdin_ffi())
}

///|
/// 把二进制写到 stdout；非 native 目标返回 `false`。
#cfg(target="native")
pub fn write_stdout_bytes(data : Bytes) -> Bool {
  write_stdout_ffi(data)
  true
}

///|
#cfg(not(target="native"))
pub fn read_stdin_bytes() -> Bytes? {
  None
}

///|
#cfg(not(target="native"))
pub fn write_stdout_bytes(data : Bytes) -> Bool {
  ignore(data)
  false
}

///|
/// 路径是否为 stdin 占位符。
pub fn is_stdin_path(path : String) -> Bool {
  path == "-"
}

///|
/// 路径是否为 stdout 占位符。
pub fn is_stdout_path(path : String) -> Bool {
  path == "-"
}

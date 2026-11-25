/*
 * imgtool 的 stdin/stdout 桥。
 *
 * MoonBit 公开 API 里没有读 stdin 的入口（`moonbitlang/core/env` 只有 args /
 * exit / now），`moonbitlang/x/fs` 也只接受路径，所以在 imgcli 包里挂一个最小
 * C 桩：`-` 作为输入路径时把整条 stdin 读进来，`-` 作为输出路径时把二进制写
 * 到 stdout（JSON 结果改走 stderr）。只在 native 目标编译。
 */

#include <moonbit.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

/* Windows 默认文本模式会把 0x1A 当 EOF、把 \r\n 折叠，二进制管道必须切过来。 */
static void ensure_binary_stdio(void) {
#ifdef _WIN32
  _setmode(_fileno(stdin), _O_BINARY);
  _setmode(_fileno(stdout), _O_BINARY);
#endif
}

/* stdin 读全量：扩容策略 64KB 起、满则翻倍，读完返回 Bytes。 */
MOONBIT_EXPORT moonbit_bytes_t moonbit_imgcli_read_stdin(void) {
  ensure_binary_stdio();
  int32_t cap = 1 << 16;
  int32_t len = 0;
  char *buf = (char *)malloc((size_t)cap);
  if (buf == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  for (;;) {
    if (len == cap) {
      int32_t ncap = cap * 2;
      char *nbuf = (char *)realloc(buf, (size_t)ncap);
      if (nbuf == NULL) {
        break;
      }
      buf = nbuf;
      cap = ncap;
    }
    size_t got = fread(buf + len, 1, (size_t)(cap - len), stdin);
    if (got == 0) {
      break;
    }
    len += (int32_t)got;
  }
  moonbit_bytes_t out = moonbit_make_bytes(len, 0);
  if (len > 0) {
    memcpy(out, buf, (size_t)len);
  }
  free(buf);
  return out;
}

/* 二进制写 stdout：imgtool convert - - 这类管道场景用，避免 println 加换行。 */
MOONBIT_EXPORT void moonbit_imgcli_write_stdout(moonbit_bytes_t bytes) {
  ensure_binary_stdio();
  int32_t len = Moonbit_array_length(bytes);
  if (len > 0) {
    fwrite(bytes, 1, (size_t)len, stdout);
  }
  fflush(stdout);
}

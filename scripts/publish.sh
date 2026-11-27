#!/usr/bin/env bash
# publish.sh — 兼容入口。实际实现见 scripts/publish.mjs（11 环顺序 + 前置门禁 + 中断续发）。
#
#   bash scripts/publish.sh --dry-run        # 等价 node scripts/publish.mjs
#   bash scripts/publish.sh --exec           # 等价 node scripts/publish.mjs --exec
set -euo pipefail
exec node "$(cd "$(dirname "$0")" && pwd)/publish.mjs" "$@"

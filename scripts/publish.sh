#!/usr/bin/env bash
# publish.sh — 七模块按依赖序发布（发布命令由维护者亲自执行）
#
# 用法：
#   bash scripts/publish.sh --dry-run   # 版本占用预检（202/409 判定）
#   bash scripts/publish.sh             # 正式发布（每步 moon update）
#
# 依赖顺序：core → codec → process → photography → vision → domain → 根模块。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY=1
fi

ORDER=(image.core image.codec image.process image.photography image.vision image.domain .)

for module in "${ORDER[@]}"; do
  dir="$ROOT/$module"
  echo "== publish: $module =="
  (
    cd "$dir"
    if [[ $DRY -eq 1 ]]; then
      moon publish --dry-run
    else
      moon publish
    fi
  )
  if [[ $DRY -eq 0 ]]; then
    (
      cd "$ROOT"
      moon update
    )
  fi
done

echo "publish sequence finished (mode: $([[ $DRY -eq 1 ]] && echo dry-run || echo publish))"
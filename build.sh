#!/usr/bin/env bash
# Build a .plugin file for every plugin under ./plugins into ./dist
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
rm -f "$DIST"/*.plugin 2>/dev/null || true

for dir in "$ROOT"/plugins/*/; do
  name="$(python3 -c "import json,sys; print(json.load(open('$dir/.claude-plugin/plugin.json'))['name'])")"
  out="$DIST/$name.plugin"
  ( cd "$dir" && zip -r "$out" . -x "*.DS_Store" -x "*.plugin" >/dev/null )
  echo "built  $out"
done

echo "done -> $DIST"

#!/usr/bin/env bash
# feed.sh — publish one Work Board feed. Called by the watch-loop skills.
#
#   feed.sh <name> <<'JSON'
#   {"items":[...]}
#   JSON
#
# Adds generated_at, writes data/<name>.json (the contract) and data/<name>.js
# (the wrapper the board loads via <script>, because fetch() cannot read a sibling
# file from a file:// page). Both writes are atomic.
set -euo pipefail
name="${1:?usage: feed.sh <name>  (JSON on stdin)}"
dir="$HOME/.claude/dashboard/data"; mkdir -p "$dir"

payload=$(cat)
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || { echo "feed.sh: $name — invalid JSON, refusing to write" >&2; exit 1; }

printf '%s' "$payload" \
  | jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {generated_at:$now}' \
  > "$dir/$name.json.tmp" && mv "$dir/$name.json.tmp" "$dir/$name.json"

{ printf 'WB.set("%s",' "$name"; cat "$dir/$name.json"; printf ');\n'; } \
  > "$dir/$name.js.tmp" && mv "$dir/$name.js.tmp" "$dir/$name.js"

echo "feed.sh: wrote $name ($(jq -r '(.items|length)? // "no items[]"' "$dir/$name.json"))"

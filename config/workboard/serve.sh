#!/usr/bin/env bash
# serve.sh — keep the Work Board served on 127.0.0.1:8777.
# Idempotent: exits quietly if it is already up, so cron can call it as a watchdog.
# Bound to loopback only — reachable through the SSH tunnel, never from the network.
set -uo pipefail
PORT=8777
DIR="$HOME/.claude/dashboard"
LOG="$HOME/.claude/dashboard/.serve.log"

if curl -s -m 2 -o /dev/null "http://127.0.0.1:$PORT/index.html" 2>/dev/null; then
  [ "${1:-}" = "--quiet" ] || echo "already serving on $PORT"
  exit 0
fi

pkill -f "http.server $PORT" 2>/dev/null
nohup python3 -m http.server "$PORT" --bind 127.0.0.1 -d "$DIR" >"$LOG" 2>&1 &
sleep 1

if curl -s -m 3 -o /dev/null -w '' "http://127.0.0.1:$PORT/index.html"; then
  echo "serving $DIR on http://127.0.0.1:$PORT  (pid $(pgrep -f "http.server $PORT" | head -1))"
else
  echo "failed to start; see $LOG" >&2
  exit 1
fi

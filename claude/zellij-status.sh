#!/usr/bin/env bash
# Drive zellij pane name from Claude Code hooks + skill annotations.
#
# State machine: one JSON file per pane, atomic writes, flock-guarded.
# Each hook = one subcommand that mutates state and re-renders.
#
# Render priority for primary label (highest first):
#   ⚠ error  >  🗜 compacting  >  🔔 perm  >  ❓ elicit
#   >  🎯 detail (skill self-report)
#   >  📋 current_task (TaskUpdate in_progress)
#   >  active tools joined by ·
#   >  📜 skill:action (UserPromptExpansion, no other activity)
#   >  ✓ done  >  💤 idle  >  💭 thinking
#
# Suffixes always appended in order:
#   · <ticket>   (<done>/<total>)   [<n>/<m> <label>]
set -uo pipefail

[ -z "${ZELLIJ:-}" ] && exit 0

PANE_ID="${ZELLIJ_PANE_ID:-0}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-zellij"
STATE_FILE="$CACHE_DIR/$PANE_ID.json"
LOCK_FILE="$CACHE_DIR/$PANE_ID.lock"
mkdir -p "$CACHE_DIR"

DEFAULT_STATE='{"ticket":null,"topic":null,"phase":"thinking","active":[],"tasks_total":0,"tasks_done":0,"compacting":false,"perm":false,"elicit_server":null,"error_type":null,"skill":null,"detail":null,"current_task":null,"tasks_map":{},"progress":null}'

# ── State I/O ──────────────────────────────────────────────────────────────────

read_state() {
  if [ -s "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    printf '%s' "$DEFAULT_STATE"
  fi
}

write_state() {
  local tmp="$STATE_FILE.tmp.$$"
  printf '%s' "$1" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# mutate <handler-fn> [args...]: lock, read, hand state+args to handler, write, render.
mutate() {
  local fn="$1"; shift
  exec 9>"$LOCK_FILE"
  if ! flock -w 2 9; then exit 0; fi
  local cur new
  cur=$(read_state)
  new=$("$fn" "$cur" "$@") || new="$cur"
  [ -z "$new" ] && new="$cur"
  write_state "$new"
  render "$new"
  exec 9>&-
}

# ── Context extraction ─────────────────────────────────────────────────────────

extract_ticket() {
  local prompt="$1" cwd="${2:-$PWD}" t branch top
  t=$(printf '%s' "$prompt" | grep -oE '\b[A-Z]{2,10}-[0-9]+\b' | head -1)
  [ -n "$t" ] && { printf '%s' "$t"; return; }
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null) || branch=""
  t=$(printf '%s' "$branch" | grep -oE '[A-Z]{2,10}-[0-9]+' | head -1)
  [ -n "$t" ] && { printf '%s' "$t"; return; }
  top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null) || top=""
  printf '%s' "$top" | grep -oE '[A-Z]{2,10}-[0-9]+' | head -1
}

# tool_label <tool_name> <tool_input_json> → human label
tool_label() {
  local tool="$1" input="$2" v
  case "$tool" in
    Bash)
      v=$(printf '%s' "$input" | jq -r '.description // ""')
      if [ -z "$v" ]; then
        v=$(printf '%s' "$input" | jq -r '.command // ""' | tr '\n\t' '  ' | cut -c1-30)
      fi
      printf '$ %s' "$v"
      ;;
    Edit|Write|NotebookEdit)
      v=$(printf '%s' "$input" | jq -r '.file_path // .notebook_path // ""')
      printf '✎ %s' "${v##*/}"
      ;;
    Read)
      v=$(printf '%s' "$input" | jq -r '.file_path // ""')
      printf '👁 %s' "${v##*/}"
      ;;
    Grep|Glob)
      v=$(printf '%s' "$input" | jq -r '.pattern // ""')
      printf '🔍 %s' "$v"
      ;;
    WebFetch)
      v=$(printf '%s' "$input" | jq -r '.url // ""' | sed -E 's|^https?://([^/]+).*|\1|')
      printf '🌐 %s' "$v"
      ;;
    WebSearch)
      v=$(printf '%s' "$input" | jq -r '.query // ""')
      printf '🌐 %s' "$v"
      ;;
    Agent)
      v=$(printf '%s' "$input" | jq -r '.subagent_type // "agent"')
      printf '🤖 %s' "$v"
      ;;
    AskUserQuestion)
      printf '❓ asking'
      ;;
    ExitPlanMode)
      printf '📋 plan'
      ;;
    mcp__*)
      v="${tool#mcp__}"
      v="${v%%__*}"
      printf '⚙ %s' "$v"
      ;;
    *)
      printf '⚒ %s' "$tool"
      ;;
  esac
}

# ── Render ─────────────────────────────────────────────────────────────────────

render() {
  local s="$1" label_cache="$CACHE_DIR/$PANE_ID.label" last=""
  local error_type compacting perm elicit detail current_task phase ticket topic tasks_done tasks_total active_labels skill_label progress_str
  IFS=$'\x1f' read -r error_type compacting perm elicit detail current_task phase ticket topic tasks_done tasks_total active_labels skill_label progress_str < <(
    printf '%s' "$s" | jq -r --arg sep $'\x1f' '[
      (.error_type // ""),
      (.compacting | tostring),
      (.perm | tostring),
      (.elicit_server // ""),
      (.detail // ""),
      (.current_task // ""),
      .phase,
      (.ticket // ""),
      (.topic // ""),
      (.tasks_done | tostring),
      (.tasks_total | tostring),
      ([.active[].label] | join(" · ")),
      (if .skill then "\(.skill.name)\(if (.skill.action // "") != "" then ":\(.skill.action)" else "" end)" else "" end),
      (if .progress then "\(.progress.n)/\(.progress.m)\(if (.progress.label // "") != "" then " \(.progress.label)" else "" end)" else "" end)
    ] | join($sep)'
  )

  local ticket_suffix="" tasks_suffix="" progress_suffix="" label fallback_ctx
  [ -n "$ticket" ] && ticket_suffix=" · $ticket"
  # Fallback context for idle/done/thinking: prefer ticket, then topic, then "Claude".
  fallback_ctx="${ticket_suffix:- ${topic:-Claude}}"
  if [ "${tasks_total:-0}" -gt 0 ]; then
    tasks_suffix=" ($tasks_done/$tasks_total)"
  fi
  [ -n "$progress_str" ] && progress_suffix=" [$progress_str]"

  if [ -n "$error_type" ]; then
    label="⚠ ${error_type}${ticket_suffix}"
  elif [ "$compacting" = "true" ]; then
    label="🗜 compacting"
  elif [ "$perm" = "true" ]; then
    label="🔔 perm${ticket_suffix}"
  elif [ -n "$elicit" ]; then
    label="❓ ${elicit}${ticket_suffix}"
  elif [ -n "$detail" ]; then
    label="🎯 ${detail}${ticket_suffix}${tasks_suffix}${progress_suffix}"
  elif [ -n "$current_task" ]; then
    label="📋 ${current_task}${ticket_suffix}${tasks_suffix}${progress_suffix}"
  elif [ -n "$active_labels" ]; then
    label="${active_labels}${ticket_suffix}${tasks_suffix}${progress_suffix}"
  elif [ -n "$skill_label" ]; then
    label="📜 ${skill_label}${ticket_suffix}${tasks_suffix}"
  elif [ "$phase" = "done" ]; then
    label="✓${fallback_ctx}${tasks_suffix}"
  elif [ "$phase" = "idle" ]; then
    label="💤${fallback_ctx}${tasks_suffix}"
  else
    label="💭${fallback_ctx}${tasks_suffix}"
  fi

  # Skip the zellij IPC call when the label hasn't changed.
  [ -f "$label_cache" ] && last=$(cat "$label_cache" 2>/dev/null)
  [ "$label" = "$last" ] && return
  printf '%s' "$label" > "$label_cache"
  zellij action rename-pane --pane-id "$PANE_ID" "$label" >/dev/null 2>&1 || true
}

# ── Hook handlers ──────────────────────────────────────────────────────────────

handler_init() {
  local input cwd ticket
  input=$(cat 2>/dev/null || true)
  cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)
  [ -z "$cwd" ] && cwd="$PWD"
  ticket=$(extract_ticket "" "$cwd")
  printf '%s' "$DEFAULT_STATE" | jq -c --arg t "$ticket" \
    '. * {ticket: (if $t=="" then null else $t end)}'
}

handler_turn() {
  local input cwd prompt ticket topic
  input=$(cat 2>/dev/null || true)
  cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
  prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')
  ticket=$(extract_ticket "$prompt" "$cwd")
  # First substantive prompt of the session becomes the topic (40 chars, single-line).
  # Skip trivial prompts (<12 chars after normalization) so words like "retry" don't stick.
  topic=$(printf '%s' "$prompt" | tr '\n\t' '  ' | sed 's/^ *//;s/ *$//')
  if [ "${#topic}" -lt 12 ]; then
    topic=""
  else
    topic=$(printf '%s' "$topic" | cut -c1-40)
  fi
  # Don't touch skill/detail/progress here — expand may have set them just before this hook.
  printf '%s' "$1" | jq -c --arg t "$ticket" --arg tp "$topic" \
    '. * {ticket: (if $t=="" then null else $t end), phase:"thinking", perm:false, elicit_server:null, error_type:null}
     | .topic = (if (.topic // "") == "" and $tp != "" then $tp else .topic end)'
}

handler_expand() {
  local input cname cargs
  input=$(cat 2>/dev/null || true)
  cname=$(printf '%s' "$input" | jq -r '.command_name // ""')
  cargs=$(printf '%s' "$input" | jq -r '.command_args // ""')
  # New slash command → fresh turn-scoped fields.
  printf '%s' "$1" | jq -c --arg n "$cname" --arg a "$cargs" \
    '.skill = (if $n == "" then null else {name:$n, action:$a} end) | .detail = null | .progress = null'
}

handler_tool_start() {
  local input tool tool_input tool_id label state="$1"
  input=$(cat 2>/dev/null || true)
  tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
  tool_input=$(printf '%s' "$input" | jq -c '.tool_input // {}')
  tool_id=$(printf '%s' "$input" | jq -r '.tool_use_id // ""')

  case "$tool" in
    Skill)
      local sname sargs
      sname=$(printf '%s' "$tool_input" | jq -r '.skill // ""')
      sargs=$(printf '%s' "$tool_input" | jq -r '.args // ""')
      printf '%s' "$state" | jq -c --arg n "$sname" --arg a "$sargs" \
        '.skill = (if $n == "" then .skill else {name:$n, action:$a} end) | .perm=false'
      return
      ;;
    TaskCreate|TaskGet|TaskList)
      printf '%s' "$state" | jq -c '.perm=false'
      return
      ;;
    TaskUpdate)
      local task_id status new_title
      task_id=$(printf '%s' "$tool_input" | jq -r '.taskId // ""')
      status=$(printf '%s' "$tool_input" | jq -r '.status // ""')
      # Capture inline subject/activeForm changes too.
      new_title=$(printf '%s' "$tool_input" | jq -r '.activeForm // .subject // ""')
      printf '%s' "$state" | jq -c --arg id "$task_id" --arg st "$status" --arg nt "$new_title" \
        'if $nt != "" then .tasks_map[$id] = ((.tasks_map[$id] // {}) + {title:$nt}) else . end |
         if $st == "in_progress" then .current_task = (.tasks_map[$id].title // null)
         elif $st == "completed" then (if .current_task == .tasks_map[$id].title then .current_task = null else . end)
         else . end | .perm=false'
      return
      ;;
  esac

  label=$(tool_label "$tool" "$tool_input")
  printf '%s' "$state" | jq -c --arg id "$tool_id" --arg lbl "$label" \
    '.active += [{id:$id, label:$lbl}] | .perm=false | .phase="thinking" | .error_type=null'
}

handler_tool_end() {
  local input tool_id
  input=$(cat 2>/dev/null || true)
  tool_id=$(printf '%s' "$input" | jq -r '.tool_use_id // ""')
  printf '%s' "$1" | jq -c --arg id "$tool_id" '.active |= map(select(.id != $id))'
}

handler_batch_end() {
  printf '%s' "$1" | jq -c '.active=[] | .perm=false'
}

handler_subagent_start() {
  local input atype aid
  input=$(cat 2>/dev/null || true)
  atype=$(printf '%s' "$input" | jq -r '.agent_type // "agent"')
  aid=$(printf '%s' "$input" | jq -r '.agent_id // ""')
  printf '%s' "$1" | jq -c --arg id "sub:$aid" --arg lbl "🤖 $atype" \
    '.active += [{id:$id, label:$lbl}]'
}

handler_subagent_end() {
  local input aid
  input=$(cat 2>/dev/null || true)
  aid=$(printf '%s' "$input" | jq -r '.agent_id // ""')
  printf '%s' "$1" | jq -c --arg id "sub:$aid" '.active |= map(select(.id != $id))'
}

handler_compact_start() { printf '%s' "$1" | jq -c '.compacting=true'; }
handler_compact_end()   { printf '%s' "$1" | jq -c '.compacting=false'; }

handler_notify() {
  local input ntype
  input=$(cat 2>/dev/null || true)
  ntype=$(printf '%s' "$input" | jq -r '.notification_type // ""')
  case "$ntype" in
    permission_prompt) printf '%s' "$1" | jq -c '.perm=true' ;;
    idle_prompt)       printf '%s' "$1" | jq -c '.phase="idle" | .perm=false' ;;
    *)                 printf '%s' "$1" ;;
  esac
}

handler_elicit_start() {
  local input server
  input=$(cat 2>/dev/null || true)
  server=$(printf '%s' "$input" | jq -r '.server_name // "mcp"')
  printf '%s' "$1" | jq -c --arg s "$server" '.elicit_server=$s'
}

handler_elicit_end() { printf '%s' "$1" | jq -c '.elicit_server=null'; }

handler_stop() {
  # End of turn: clear all turn-scoped state.
  printf '%s' "$1" | jq -c \
    '.phase="done" | .perm=false | .active=[] | .error_type=null |
     .skill=null | .detail=null | .current_task=null | .progress=null'
}

handler_stop_error() {
  local input etype
  input=$(cat 2>/dev/null || true)
  etype=$(printf '%s' "$input" | jq -r '.error_type // "error"')
  printf '%s' "$1" | jq -c --arg e "$etype" '.error_type=$e | .active=[] | .perm=false'
}

handler_task_created() {
  local input task_id task_title
  input=$(cat 2>/dev/null || true)
  task_id=$(printf '%s' "$input" | jq -r '.task_id // ""')
  task_title=$(printf '%s' "$input" | jq -r '.task_title // ""')
  printf '%s' "$1" | jq -c --arg id "$task_id" --arg t "$task_title" \
    '.tasks_total += 1 | .tasks_map[$id] = ((.tasks_map[$id] // {}) + {title:$t})'
}

handler_task_completed() {
  local input task_id
  input=$(cat 2>/dev/null || true)
  task_id=$(printf '%s' "$input" | jq -r '.task_id // ""')
  printf '%s' "$1" | jq -c --arg id "$task_id" \
    '.tasks_done += 1 |
     (if .current_task == (.tasks_map[$id].title // "") then .current_task = null else . end) |
     del(.tasks_map[$id])'
}

# ── Skill-callable subcommands ─────────────────────────────────────────────────

handler_status() {
  local state="$1" d="${2:-}"
  printf '%s' "$state" | jq -c --arg d "$d" \
    '.detail = (if $d == "" then null else $d end)'
}

handler_topic() {
  local state="$1" t="${2:-}"
  # Normalize: single-line, trimmed, 40 chars. Empty arg clears the topic.
  t=$(printf '%s' "$t" | tr '\n\t' '  ' | sed 's/^ *//;s/ *$//' | cut -c1-40)
  printf '%s' "$state" | jq -c --arg t "$t" \
    '.topic = (if $t == "" then null else $t end)'
}

handler_progress() {
  local state="$1" n="${2:-}" m="${3:-}" lbl="${4:-}"
  if [ -z "$n" ] || [ -z "$m" ]; then
    printf '%s' "$state" | jq -c '.progress = null'
    return
  fi
  # Validate numeric; if not, clear.
  if ! [[ "$n" =~ ^[0-9]+$ ]] || ! [[ "$m" =~ ^[0-9]+$ ]]; then
    printf '%s' "$state" | jq -c '.progress = null'
    return
  fi
  printf '%s' "$state" | jq -c --argjson n "$n" --argjson m "$m" --arg l "$lbl" \
    '.progress = {n:$n, m:$m, label:$l}'
}

handler_cleanup() {
  zellij action undo-rename-pane --pane-id "$PANE_ID" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE" "$LOCK_FILE" "$CACHE_DIR/$PANE_ID.label"
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

case "${1:-}" in
  init)            mutate handler_init ;;
  turn)            mutate handler_turn ;;
  expand)          mutate handler_expand ;;
  tool_start)      mutate handler_tool_start ;;
  tool_end)        mutate handler_tool_end ;;
  batch_end)       mutate handler_batch_end ;;
  subagent_start)  mutate handler_subagent_start ;;
  subagent_end)    mutate handler_subagent_end ;;
  compact_start)   mutate handler_compact_start ;;
  compact_end)     mutate handler_compact_end ;;
  notify)          mutate handler_notify ;;
  elicit_start)    mutate handler_elicit_start ;;
  elicit_end)      mutate handler_elicit_end ;;
  stop)            mutate handler_stop ;;
  stop_error)      mutate handler_stop_error ;;
  task_created)    mutate handler_task_created ;;
  task_completed)  mutate handler_task_completed ;;
  status|label)    mutate handler_status "${2:-}" ;;
  topic)           mutate handler_topic "${2:-}" ;;
  progress)        mutate handler_progress "${2:-}" "${3:-}" "${4:-}" ;;
  cleanup)         handler_cleanup ;;
  *)               exit 0 ;;
esac

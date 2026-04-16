#!/usr/bin/env bash
# Manage Zellij pane name to reflect Claude Code status.
#
# Uses zellij action rename-pane which sets a persistent user-override name.
# This blocks Claude Code's own OSC 2 animations (spinner dot, completion star).

[ -z "$ZELLIJ" ] && exit 0

PANE_ID="${ZELLIJ_PANE_ID:-0}"
CONTEXT_FILE="/tmp/claude-zellij-context-${PANE_ID}.txt"
BG_FLAG="/tmp/claude-zellij-bg-${PANE_ID}"

# ── Context extraction ─────────────────────────────────────────────────────────

extract_verb() {
  local msg="${1,,}"
  case "$msg" in
    *implement*|*build*|*creat*|*add*|*writ*|*develop*|*generat*) echo "implementing" ;;
    *fix*|*debug*|*resolv*|*patch*)                                echo "fixing"        ;;
    *research*|*explor*|*find*|*search*|*investigat*|*analys*|*analyz*) echo "researching" ;;
    *review*|*read*|*"look at"*)                                   echo "reviewing"     ;;
    *plan*|*design*|*architect*)                                   echo "planning"      ;;
    *test*|*verif*)                                                echo "testing"       ;;
    *refactor*|*clean*|*restructur*)                               echo "refactoring"   ;;
    *deploy*|*releas*|*publish*)                                   echo "deploying"     ;;
    *update*|*upgrad*|*migrat*)                                    echo "updating"      ;;
    *run*|*exec*|*ls*|*show*|*list*|*print*)                      echo "running"       ;;
    *why*|*what*|*how*|*when*|*where*|*explain*|*tell*|*describ*) echo "discussing"    ;;
    *)                                                             echo "working on"    ;;
  esac
}

extract_context() {
  local msg="$1" ticket branch

  ticket=$(printf '%s' "$msg" | grep -oE '\b[A-Z]{2,10}-[0-9]+\b' | head -1)
  [ -n "$ticket" ] && echo "$ticket" && return

  branch=$(git branch --show-current 2>/dev/null)
  ticket=$(printf '%s' "$branch" | grep -oE '[A-Z]{2,10}-[0-9]+' | head -1)
  [ -n "$ticket" ] && echo "$ticket" && return

  if [ -n "$branch" ] && [[ "$branch" != "main" && "$branch" != "master" && "$branch" != "HEAD" ]]; then
    printf '%s' "$branch" | sed 's|.*/||' | cut -c1-20
    return
  fi

  basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" | cut -c1-20
}

saved_label() {
  cat "$CONTEXT_FILE" 2>/dev/null || echo "Claude Code"
}

# ── States ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  notification)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "🔔 $(saved_label)"
    ;;

  resume)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ $(saved_label)"
    ;;

  pretool)
    # PreToolUse: detect background Bash tasks via stdin JSON
    input=$(cat)
    is_bg=$(printf '%s' "$input" | jq -r '.tool_input.run_in_background // false' 2>/dev/null)
    if [[ "$is_bg" == "true" ]]; then
      touch "$BG_FLAG"
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ bg: $(saved_label)"
    else
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ $(saved_label)"
    fi
    ;;

  working)
    rm -f "$BG_FLAG"
    input=$(cat)
    msg=$(printf '%s' "$input" | jq -r '.message // .user_message // .content // empty' 2>/dev/null)
    context=$(extract_context "$msg")
    [ -z "$context" ] && context="Code"
    verb=$(extract_verb "$msg")
    label="${verb:+${verb} }${context}"
    printf '%s' "$label" > "$CONTEXT_FILE"
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ ${label}"
    ;;

  done)
    if [ -f "$BG_FLAG" ]; then
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ waiting… $(saved_label)"
    else
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "💤 $(saved_label)"
    fi
    ;;

  waiting)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "💤 Claude Code"
    ;;

  idle)
    zellij action undo-rename-pane --pane-id "$ZELLIJ_PANE_ID" 2>/dev/null || true
    rm -f "$CONTEXT_FILE" "$BG_FLAG"
    ;;
esac

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
  local msg="$1" dir="${2:-}" ticket branch toplevel

  # 1. Ticket in message
  ticket=$(printf '%s' "$msg" | grep -oE '\b[A-Z]{2,10}-[0-9]+\b' | head -1)
  [ -n "$ticket" ] && echo "$ticket" && return

  # 2. Ticket in branch name
  if [ -n "$dir" ]; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  else
    branch=$(git branch --show-current 2>/dev/null)
  fi
  ticket=$(printf '%s' "$branch" | grep -oE '[A-Z]{2,10}-[0-9]+' | head -1)
  [ -n "$ticket" ] && echo "$ticket" && return

  # 3. Ticket in worktree/repo path
  if [ -n "$dir" ]; then
    toplevel=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")
  else
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  fi
  ticket=$(printf '%s' "$toplevel" | grep -oE '[A-Z]{2,10}-[0-9]+' | head -1)
  [ -n "$ticket" ] && echo "$ticket" && return

  # 4. Non-main branch name (shortened)
  if [ -n "$branch" ] && [[ "$branch" != "main" && "$branch" != "master" && "$branch" != "HEAD" ]]; then
    printf '%s' "$branch" | sed 's|.*/||' | cut -c1-20
    return
  fi

  # 5. Repo/worktree directory name
  basename "$toplevel" | cut -c1-20
}

extract_desc() {
  local dir="$1" toplevel ticket_file desc
  [ -z "$dir" ] && return
  toplevel=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return
  ticket_file="$toplevel/TICKET.md"
  [ -f "$ticket_file" ] || return
  # First line format: "# UCSD-XXXX: Short desc: more stuff"
  # Take the part after "# XXXX-NNN: " and before the next ":"
  desc=$(head -1 "$ticket_file" | sed 's/^# [A-Z]*-[0-9]*: //' | cut -d: -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]*$//' | cut -c1-25)
  printf '%s' "$desc"
}

extract_skill_label() {
  local msg="$1" lmsg ticket
  lmsg="${msg,,}"
  [[ "$lmsg" != /* ]] && return
  ticket=$(printf '%s' "$msg" | grep -oE '\b[A-Z]{2,10}-[0-9]+\b' | head -1)
  case "$lmsg" in
    /clean\ all*|/wt-check*)    echo "cleaning worktrees"                   ;;
    /clean*)                    echo "cleaning${ticket:+ $ticket}"          ;;
    /rebase\ all*)              echo "rebasing all worktrees"               ;;
    /rebase*)                   echo "rebasing${ticket:+ $ticket}"          ;;
    /publish*)                  echo "publishing${ticket:+ $ticket}"        ;;
    /babysit*)                  echo "monitoring${ticket:+ $ticket}"        ;;
    /loop*investigate-ci*|/loop*\ */investigate-ci*)  echo "monitoring ci"                        ;;
    /loop*)                     echo "monitoring"                           ;;
    /work*|/fix-flaky*)         echo "working on${ticket:+ $ticket}"        ;;
    /investigate-ci*)           echo "investigating ci"                     ;;
    /commit-msg*)               echo "committing${ticket:+ $ticket}"        ;;
    /wt-new*)                   echo "creating worktree${ticket:+ $ticket}" ;;
    /diff-create*|/pr-create*)  echo "creating pr${ticket:+ $ticket}"       ;;
    /diff-update*|/pr-update*)  echo "updating pr${ticket:+ $ticket}"       ;;
    /jira*)                     echo "updating jira${ticket:+ $ticket}"     ;;
    /groom*)                    echo "grooming backlog"                     ;;
    /summarize*|/summary*)      echo "summarizing"                          ;;
    /compact*)                  echo "compacting"                           ;;
    /new-skill*)                echo "creating skill"                       ;;
    *)                          echo ""                                     ;;
  esac
}

pick_emoji() {
  local label="${1,,}"
  case "$label" in
    *monitoring*|*watching*) echo "👁️" ;;
    *)                       echo "⏳" ;;
  esac
}

saved_label() {
  cat "$CONTEXT_FILE" 2>/dev/null || echo "Claude Code"
}

# ── States ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  label)
    label="${2:-}"
    if [ -n "$label" ]; then
      printf '%s' "$label" > "$CONTEXT_FILE"
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "$(pick_emoji "$label") ${label}"
    else
      rm -f "$CONTEXT_FILE"
    fi
    ;;

  notification)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "🔔 $(saved_label)"
    ;;

  resume)
    label=$(saved_label)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "$(pick_emoji "$label") ${label}"
    ;;

  pretool)
    # PreToolUse: detect background Bash tasks via stdin JSON
    input=$(cat)
    is_bg=$(printf '%s' "$input" | jq -r '.tool_input.run_in_background // false' 2>/dev/null)
    if [[ "$is_bg" == "true" ]]; then
      touch "$BG_FLAG"
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ bg: $(saved_label)"
    else
      label=$(saved_label)
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "$(pick_emoji "$label") ${label}"
    fi
    ;;

  working)
    rm -f "$BG_FLAG"
    input=$(cat)
    msg=$(printf '%s' "$input" | jq -r '.message // .user_message // .content // empty' 2>/dev/null)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
    label=$(extract_skill_label "$msg" "$cwd")
    if [ -z "$label" ]; then
      context=$(extract_context "$msg" "$cwd")
      desc=$(extract_desc "$cwd")
      [ -z "$context" ] && context="Code"
      verb=$(extract_verb "$msg")
      label="${verb:+${verb} }${context}${desc:+ ${desc}}"
    fi
    printf '%s' "$label" > "$CONTEXT_FILE"
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "$(pick_emoji "$label") ${label}"
    ;;

  done)
    if [ -f "$BG_FLAG" ]; then
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "⏳ waiting… $(saved_label)"
    else
      zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "💤 $(saved_label)"
      printf '%s' "Claude Code" > "$CONTEXT_FILE"
    fi
    ;;

  waiting)
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "💤 Claude Code"
    ;;

  idle)
    input=$(cat 2>/dev/null)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
    [ -z "$cwd" ] && cwd="$PWD"
    zellij action rename-pane --pane-id "$ZELLIJ_PANE_ID" "$(basename "$cwd")" 2>/dev/null || true
    rm -f "$CONTEXT_FILE" "$BG_FLAG"
    ;;
esac

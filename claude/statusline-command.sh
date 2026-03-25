#!/usr/bin/env bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
style=$(echo "$input" | jq -r '.output_style.name')
dir=$(echo "$input" | jq -r '.workspace.current_dir')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // ""')
remaining=${remaining%%.*}
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size')
buffer=33000
effective=$(($ctx_size - $buffer))

branch=$(git -C "$dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

printf "\033[36m🤖 %s\033[0m \033[35m📝 %s\033[0m \033[34m📁 %s\033[0m" "$model" "$style" "$dir"

if [ -n "$branch" ]; then
  printf " \033[33m🌿 %s\033[0m" "$branch"
fi

if [ -n "$remaining" ] && [ "$remaining" != "null" ]; then
  used=$(( ($ctx_size * (100 - $remaining)) / 100 - $buffer ))
  if [ "$used" -lt 0 ]; then used=0; fi
  used_pct=$(( ($used * 100) / $effective ))
  if [ "$used_pct" -le 30 ]; then
    printf " 💾 \033[32m%s%% (%dk/%dk)\033[0m" "$used_pct" "$(($used / 1000))" "$(($effective / 1000))"
  elif [ "$used_pct" -le 60 ]; then
    printf " 💾 \033[33m%s%% (%dk/%dk)\033[0m" "$used_pct" "$(($used / 1000))" "$(($effective / 1000))"
  else
    printf " 💾 \033[31m%s%% (%dk/%dk)\033[0m" "$used_pct" "$(($used / 1000))" "$(($effective / 1000))"
  fi
fi

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_cents=$(echo "$cost" | awk '{printf "%d", $1 * 100}')
  if [ "$cost_cents" -lt 10 ]; then
    printf " 💰 \033[32m\$%.4f\033[0m" "$cost"
  elif [ "$cost_cents" -lt 100 ]; then
    printf " 💰 \033[33m\$%.4f\033[0m" "$cost"
  else
    printf " 💰 \033[31m\$%.4f\033[0m" "$cost"
  fi
fi

printf "\n"

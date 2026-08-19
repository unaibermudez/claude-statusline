#!/usr/bin/env bash
input=$(cat)

# ── ANSI colors ────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Foreground
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[34m'
MAGENTA='\033[35m'
RED='\033[31m'
WHITE='\033[97m'
GRAY='\033[90m'

# ── Helpers ────────────────────────────────────────────────────────────────────

# progress_bar <pct> <width>
# Renders a filled/empty bar and picks a color based on usage level.
progress_bar() {
  local pct=$1
  local width=${2:-10}
  local filled=$(( (pct * width + 50) / 100 ))   # round
  (( filled > width )) && filled=$width
  local empty=$(( width - filled ))

  local bar_color
  if   (( pct >= 80 )); then bar_color="$RED"
  elif (( pct >= 50 )); then bar_color="$YELLOW"
  else                       bar_color="$GREEN"
  fi

  local bar="${bar_color}"
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  bar+="${GRAY}"
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  bar+="${RESET}"

  printf "%s" "$bar"
}

# colored_pct <pct>  — prints the percentage number in the appropriate color
colored_pct() {
  local pct=$1
  local color
  if   (( pct >= 80 )); then color="$RED"
  elif (( pct >= 50 )); then color="$YELLOW"
  else                       color="$GREEN"
  fi
  printf "${color}${BOLD}%d%%${RESET}" "$pct"
}

# ── Data extraction ────────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
folder=$(basename "$cwd")

branch=""
if [ -n "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
        || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

model=$(echo "$input" | jq -r '.model.display_name // ""')

ctx_used=$(echo "$input"  | jq -r '.context_window.used_percentage  // empty')
five=$(echo     "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo     "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Assemble parts ─────────────────────────────────────────────────────────────
SEP="${GRAY} │ ${RESET}"
parts=()

# Folder + Branch (combined)
if [ -n "$folder" ]; then
  loc="${CYAN}${BOLD}${folder}${RESET}"
  if [ -n "$branch" ]; then
    loc+="${GRAY}:${RESET}${YELLOW}${branch}${RESET}"
  fi
  parts+=("$loc")
fi

# Model
if [ -n "$model" ]; then
  parts+=("${MAGENTA}${model}${RESET}")
fi

# Context window
if [ -n "$ctx_used" ]; then
  pct=$(printf '%.0f' "$ctx_used")
  bar=$(progress_bar "$pct" 8)
  num=$(colored_pct  "$pct")
  parts+=("${WHITE}ctx${RESET} ${bar} ${num}")
fi

# 5-hour rate limit + countdown
if [ -n "$five" ]; then
  pct=$(printf '%.0f' "$five")
  bar=$(progress_bar "$pct" 8)
  num=$(colored_pct  "$pct")

  countdown=""
  if [ -n "$five_reset" ] && [ "$five_reset" != "null" ]; then
    now=$(date +%s)
    diff=$(( five_reset - now ))
    if (( diff > 0 )); then
      h=$(( diff / 3600 ))
      m=$(( (diff % 3600) / 60 ))
      countdown=" ${GRAY}(${RESET}${WHITE}$(printf '%d:%02d' $h $m)${RESET}${GRAY})${RESET}"
    fi
  fi

  parts+=("${WHITE}5h${RESET} ${bar} ${num}${countdown}")
fi

# 7-day rate limit
if [ -n "$week" ]; then
  pct=$(printf '%.0f' "$week")
  bar=$(progress_bar "$pct" 8)
  num=$(colored_pct  "$pct")
  parts+=("${WHITE}7d${RESET} ${bar} ${num}")
fi

# ── Join and print ─────────────────────────────────────────────────────────────
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="${result}${SEP}${part}"
  fi
done

printf "%b" "$result"
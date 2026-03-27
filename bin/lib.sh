#!/bin/bash
# lib.sh — shared functions for operator scripts

# ── Logging ───────────────────────────────────────────────────────────

log() {
  local msg="[$(date '+%H:%M:%S')] $1"
  echo "$msg"
  [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE" || true
}

setup_log() {
  local name=$1
  LOG_DIR="$HOME/.operator/logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/${name}-$(date +%Y%m%d-%H%M%S).log"
}

# ── Common argument parsing ───────────────────────────────────────────

MODEL=""
EFFORT=""
CLAUDE_TIMEOUT=${CLAUDE_TIMEOUT:-15}

# Try to parse a common flag. Sets PARSED_SHIFT on success; returns 1 if not recognized.
try_parse_common() {
  case $1 in
    --model)   MODEL="$2"; PARSED_SHIFT=2 ;;
    --effort)  EFFORT="$2"; PARSED_SHIFT=2 ;;
    --timeout) CLAUDE_TIMEOUT="$2"; PARSED_SHIFT=2 ;;
    *)         PARSED_SHIFT=0; return 1 ;;
  esac
}

# ── Environment validation ────────────────────────────────────────────

validate_env() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a git repository."
    exit 1
  fi
  if ! command -v claude &>/dev/null; then
    echo "Error: claude CLI is required."
    exit 1
  fi
  PROJECT_DIR="$(git rev-parse --show-toplevel)"
  cd "$PROJECT_DIR"
}

# ── Claude command builder ────────────────────────────────────────────

build_claude_cmd() {
  CLAUDE_CMD="claude --dangerously-skip-permissions --print"
  [ -n "$MODEL" ] && CLAUDE_CMD="$CLAUDE_CMD --model $MODEL"
  [ -n "$EFFORT" ] && CLAUDE_CMD="$CLAUDE_CMD --effort $EFFORT"
  return 0
}

# ── Run claude with spinner ───────────────────────────────────────────

# run_claude <prompt_file> <label> [working_dir]
# Sets CLAUDE_OUTPUT with the result. Returns 1 if timed out.
run_claude() {
  local prompt_file=$1
  local label=$2
  local work_dir=${3:-}
  local outfile
  outfile=$(mktemp)

  if [ -n "$work_dir" ]; then
    (cd "$work_dir" && command $CLAUDE_CMD < "$prompt_file" > "$outfile" 2>&1) &
  else
    command $CLAUDE_CMD < "$prompt_file" > "$outfile" 2>&1 &
  fi
  local pid=$!
  log "Claude started: $label (PID: $pid)"

  spin $pid "$label" "$outfile"
  wait $pid 2>/dev/null || true

  CLAUDE_OUTPUT=$(cat "$outfile")
  rm -f "$outfile"

  [ "$SPIN_TIMED_OUT" = true ] && return 1
  return 0
}

# ── Verification checks ──────────────────────────────────────────────

# run_check <spinner_label> <log_label> <command> [tail_lines]
# Requires PROJECT_DIR. Appends to CHECK_ERRORS on failure. Returns 0/1.
run_check() {
  local spinner_label=$1
  local log_label=$2
  local cmd=$3
  local tail_lines=${4:-40}
  local outfile
  outfile=$(mktemp)

  (cd "$PROJECT_DIR" && $cmd) > "$outfile" 2>&1 &
  local pid=$!
  spin $pid "$spinner_label"

  if wait $pid; then
    log "  $log_label: clean"
    rm -f "$outfile"
    return 0
  else
    log "  $log_label: errors"
    CHECK_ERRORS+=$'\n## '"$log_label"$' errors\n```\n'
    CHECK_ERRORS+="$(tail -"$tail_lines" "$outfile")"
    CHECK_ERRORS+=$'\n```\n'
    rm -f "$outfile"
    return 1
  fi
}

# ── Utilities ─────────────────────────────────────────────────────────

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

extract_section() {
  local file=$1
  local section=$2
  awk -v header="## $section" '
    $0 == header || index($0, header " — ") == 1 { found=1; print; next }
    found && /^## / { exit }
    found { print }
  ' "$file"
}

format_elapsed() {
  echo "$(( $1 / 60 ))m$(( $1 % 60 ))s"
}

# ── Spinner internals ─────────────────────────────────────────────────

SPIN_TIMED_OUT=false

_stall_reset() {
  _stall_last_size=0
  _stall_last_change=$SECONDS
}

# Returns 0 if stall detected, 1 if not. Sets SPIN_TIMED_OUT on stall.
_stall_detected() {
  local current_size=${1// /}
  local stall_secs=$2
  if [ "$current_size" != "$_stall_last_size" ]; then
    _stall_last_size=$current_size
    _stall_last_change=$SECONDS
    return 1
  elif (( SECONDS - _stall_last_change >= stall_secs )); then
    SPIN_TIMED_OUT=true
    return 0
  fi
  return 1
}

# ── Activity tracking ────────────────────────────────────────────────

_spin_last_output_bytes=0
_spin_activity=""
_spin_marker=""

_init_spin_activity() {
  _spin_last_output_bytes=0
  _spin_activity=""
  _spin_marker=$(mktemp)
}

_cleanup_spin_activity() {
  rm -f "$_spin_marker" 2>/dev/null
}

# Update _spin_activity with latest status signal.
# Checks output file for new text, then filesystem for recently edited files.
_update_spin_activity() {
  local outfile=${1:-}

  # Priority 1: New text in output file
  if [ -n "$outfile" ]; then
    local bytes
    bytes=$(wc -c < "$outfile" 2>/dev/null | tr -d ' ')
    if (( bytes > _spin_last_output_bytes )); then
      _spin_last_output_bytes=$bytes
      local line
      line=$(tail -5 "$outfile" 2>/dev/null \
        | grep -v '^[[:space:]]*$' | grep -v '^```' | grep -v '^[#|>]' \
        | tail -1 | sed 's/^[*_ -]*//' | cut -c1-60)
      if [ -n "$line" ]; then
        _spin_activity="$line"
        return
      fi
    fi
  fi

  # Priority 2: Recently edited source files
  if [ -n "$_spin_marker" ] && [ -f "$_spin_marker" ]; then
    local recent
    recent=$(find . -maxdepth 5 \
      \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
         -o -name '*.py' -o -name '*.sh' -o -name '*.md' \) \
      -newer "$_spin_marker" \
      ! -path '*/node_modules/*' ! -path '*/.git/*' \
      ! -path '*/dist/*' ! -path '*/.next/*' \
      2>/dev/null | head -1)
    if [ -n "$recent" ]; then
      touch "$_spin_marker"
      _spin_activity="editing ${recent#./}"
    fi
  fi
}

# Activity check for spin_all — watches multiple output files in a work dir
_update_spin_activity_multi() {
  local work_dir=$1
  local combined_bytes
  combined_bytes=$(cat "$work_dir"/output-*.md 2>/dev/null | wc -c | tr -d ' ')
  if (( combined_bytes > _spin_last_output_bytes )); then
    _spin_last_output_bytes=$combined_bytes
    local line
    line=$(cat "$work_dir"/output-*.md 2>/dev/null \
      | grep -v '^[[:space:]]*$' | grep -v '^```' | grep -v '^[#|>]' \
      | tail -1 | sed 's/^[*_ -]*//' | cut -c1-60)
    [ -n "$line" ] && _spin_activity="$line"
  fi
}

# ── Spinner — single process ─────────────────────────────────────────

spin() {
  local pid=$1
  local label=$2
  local outfile=${3:-}
  local stall_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false
  _stall_reset
  _init_spin_activity
  local check_counter=0

  # Non-TTY fallback (log files, pipes)
  if [ ! -t 1 ]; then
    echo "  $label..."
    local last_logged_activity=""
    while kill -0 "$pid" 2>/dev/null; do
      if [ -n "$outfile" ]; then
        check_counter=$((check_counter + 1))
        if (( check_counter % 10 == 0 )); then
          if _stall_detected "$(wc -c < "$outfile" 2>/dev/null || echo 0)" "$stall_secs"; then
            kill "$pid" 2>/dev/null || true
            echo "  ✗ $label no output for ${CLAUDE_TIMEOUT}m — process killed"
            _cleanup_spin_activity
            return
          fi
        fi
        if (( check_counter % 30 == 0 )); then
          _update_spin_activity "$outfile"
          if [ -n "$_spin_activity" ] && [ "$_spin_activity" != "$last_logged_activity" ]; then
            echo "    >> $_spin_activity"
            last_logged_activity="$_spin_activity"
          fi
        fi
      fi
      sleep 1
    done
    echo "  ✓ $label completed"
    _cleanup_spin_activity
    return
  fi

  # TTY with braille spinner
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local start=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    if [ -n "$outfile" ]; then
      check_counter=$((check_counter + 1))
      if (( check_counter % 50 == 0 )); then
        if _stall_detected "$(wc -c < "$outfile" 2>/dev/null || echo 0)" "$stall_secs"; then
          kill "$pid" 2>/dev/null || true
          printf "\033[2K\r  ✗ %s no output for %dm — process killed\n" "$label" "$CLAUDE_TIMEOUT"
          _cleanup_spin_activity
          return
        fi
        _update_spin_activity "$outfile"
      fi
    fi
    local elapsed=$(( SECONDS - start ))
    if [ -n "$_spin_activity" ]; then
      printf "\033[2K\r  %s %s (%dm%02ds) \033[2m>> %s\033[22m" \
        "${chars:i++%${#chars}:1}" "$label" "$(( elapsed / 60 ))" "$(( elapsed % 60 ))" "$_spin_activity"
    else
      printf "\033[2K\r  %s %s (%dm%02ds)" "${chars:i++%${#chars}:1}" "$label" "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
    fi
    sleep 0.1
  done
  local total=$(( SECONDS - start ))
  printf "\033[2K\r  ✓ %s completed (%dm%02ds)\n" "$label" "$(( total / 60 ))" "$(( total % 60 ))"
  _cleanup_spin_activity
}

# ── Spinner — multiple parallel processes ─────────────────────────────

spin_all() {
  local label=$1
  local work_dir=$2
  shift 2
  local stall_secs=$(( CLAUDE_TIMEOUT * 60 ))
  SPIN_TIMED_OUT=false
  _stall_reset
  _init_spin_activity
  local check_counter=0

  # Non-TTY fallback
  if [ ! -t 1 ]; then
    echo "  $label — $# sections..."
    local last_logged_activity=""
    while true; do
      local running=0
      for pid in "$@"; do
        kill -0 "$pid" 2>/dev/null && running=$((running + 1))
      done
      [ $running -eq 0 ] && break
      check_counter=$((check_counter + 1))
      if (( check_counter % 10 == 0 )); then
        if _stall_detected "$(cat "$work_dir"/output-*.md 2>/dev/null | wc -c || echo 0)" "$stall_secs"; then
          for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
          echo "  ✗ $label no output for ${CLAUDE_TIMEOUT}m — killed $running remaining"
          _cleanup_spin_activity
          return
        fi
      fi
      if (( check_counter % 30 == 0 )); then
        _update_spin_activity_multi "$work_dir"
        if [ -n "$_spin_activity" ] && [ "$_spin_activity" != "$last_logged_activity" ]; then
          echo "    >> $_spin_activity"
          last_logged_activity="$_spin_activity"
        fi
      fi
      sleep 1
    done
    echo "  ✓ $label complete"
    _cleanup_spin_activity
    return
  fi

  # TTY with braille spinner
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local start=$SECONDS
  local total=$#

  while true; do
    local running=0
    for pid in "$@"; do
      kill -0 "$pid" 2>/dev/null && running=$((running + 1))
    done
    [ $running -eq 0 ] && break

    check_counter=$((check_counter + 1))
    if (( check_counter % 50 == 0 )); then
      if _stall_detected "$(cat "$work_dir"/output-*.md 2>/dev/null | wc -c || echo 0)" "$stall_secs"; then
        for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
        local done_count=$(( total - running ))
        printf "\033[2K\r  ✗ %s no output for %dm — %d/%d complete, killed %d remaining\n" \
          "$label" "$CLAUDE_TIMEOUT" "$done_count" "$total" "$running"
        _cleanup_spin_activity
        return
      fi
      _update_spin_activity_multi "$work_dir"
    fi

    local elapsed=$(( SECONDS - start ))
    local done_count=$(( total - running ))
    if [ -n "$_spin_activity" ]; then
      printf "\033[2K\r  %s %s — %d/%d sections (%dm%02ds) \033[2m>> %s\033[22m" \
        "${chars:i++%${#chars}:1}" "$label" "$done_count" "$total" \
        "$(( elapsed / 60 ))" "$(( elapsed % 60 ))" "$_spin_activity"
    else
      printf "\033[2K\r  %s %s — %d/%d sections complete (%dm%02ds)" \
        "${chars:i++%${#chars}:1}" "$label" "$done_count" "$total" \
        "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
    fi
    sleep 0.1
  done

  local t=$(( SECONDS - start ))
  printf "\033[2K\r  ✓ All %d sections — %s (%dm%02ds)\n" "$total" "$label" "$(( t / 60 ))" "$(( t % 60 ))"
  _cleanup_spin_activity
}

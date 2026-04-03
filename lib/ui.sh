#!/usr/bin/env bash

# ---------------------------------------------------------------------------
#  Sp3ctraRecon  -  UI / presentation layer
#  Retro Cartoon / Vintage Animation aesthetic  (~*~ rubber-hose style ~*~)
# ---------------------------------------------------------------------------

# ── Color palette ──────────────────────────────────────────────────────────
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  # Base ANSI
  R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[34m'
  M=$'\033[35m'; C=$'\033[36m'; W=$'\033[97m'
  DIM=$'\033[2m'; BOLD=$'\033[1m'; RST=$'\033[0m'
  # Extended 256-color gradient (cyan -> magenta)
  C1=$'\033[38;5;51m'   # bright cyan
  C2=$'\033[38;5;45m'   # cyan
  C3=$'\033[38;5;39m'   # blue-cyan
  C4=$'\033[38;5;33m'   # blue
  C5=$'\033[38;5;99m'   # purple
  C6=$'\033[38;5;135m'  # magenta-purple
  C7=$'\033[38;5;171m'  # magenta
  C8=$'\033[38;5;207m'  # pink-magenta
else
  R=""; G=""; Y=""; B=""; M=""; C=""; W=""
  DIM=""; BOLD=""; RST=""
  C1=""; C2=""; C3=""; C4=""; C5=""; C6=""; C7=""; C8=""
fi

# ── Unicode support detection ──────────────────────────────────────────────
_UNICODE=1
if ! printf '\u2500' >/dev/null 2>&1 || [[ "${TERM:-}" == "dumb" ]]; then
  _UNICODE=0
fi

# ── Box-drawing helpers (with ASCII fallback) ──────────────────────────────
_box_h()  { (( _UNICODE )) && printf '─' || printf '-'; }
_box_v()  { (( _UNICODE )) && printf '│' || printf '|'; }
_box_tl() { (( _UNICODE )) && printf '┌' || printf '+'; }
_box_tr() { (( _UNICODE )) && printf '┐' || printf '+'; }
_box_bl() { (( _UNICODE )) && printf '└' || printf '+'; }
_box_br() { (( _UNICODE )) && printf '┘' || printf '+'; }
_box_lj() { (( _UNICODE )) && printf '├' || printf '+'; }
_box_rj() { (( _UNICODE )) && printf '┤' || printf '+'; }
_bullet() { (( _UNICODE )) && printf '◆' || printf '*'; }
_arrow()  { (( _UNICODE )) && printf '▶' || printf '>'; }

# ── Decorative horizontal rule ─────────────────────────────────────────────
hr() {
  local line
  line="$(printf '%80s' '' | sed "s/ /$(_box_h)/g")"
  printf '%b%s%b\n' "$DIM" "$line" "$RST"
}

# ── Gradient Banner  ~*~ Retro Cartoon Style ~*~ ──────────────────────────
banner() {
  (( QUIET_MODE == 1 )) && return 0
  (( NON_INTERACTIVE == 0 )) && clear 2>/dev/null || true

  local deco="  ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~"

  printf '%b%s%b\n' "${DIM}${C5}" "$deco" "$RST"
  printf '%b   ____        _____      _             ____                      %b\n' "$C1" "$RST"
  printf '%b  / ___| _ __ |___ /  ___| |_ _ __ __ |  _ \\ ___  ___ ___  _ __  %b\n' "$C2" "$RST"
  printf '%b  \\___ \\| '"'"'_ \\  |_ \\ / __| __| '"'"'__/ _`| |_) / _ \\/ __/ _ \\| '"'"'_ \\ %b\n' "$C3" "$RST"
  printf '%b   ___) | |_) |___) | (__| |_| | | (_|| |  _ \\  __/ (_| (_) | | | |%b\n' "$C5" "$RST"
  printf '%b  |____/| .__/|____/ \\___|\\__|_|  \\__,_|_| \\_\\___|\\___\\___/|_| |_|%b\n' "$C7" "$RST"
  printf '%b        |_|                                                         %b\n' "$C8" "$RST"
  printf '%b%s%b\n' "${DIM}${C5}" "$deco" "$RST"
  echo
  printf '  %b%b%s %s%b\n' "$BOLD" "$C2" "${APP_NAME}" "v${VERSION}" "$RST"
  printf '  %b%s%b\n' "$W" "$(msg app_tagline)" "$RST"
  printf '  %b%s%b\n' "${DIM}" "$(msg attn_root)" "$RST"
  hr
}

# ── Spinner ────────────────────────────────────────────────────────────────
_SPINNER_PID=""

spinner_start() {
  (( QUIET_MODE==1 || NON_INTERACTIVE==1 )) && return 0
  [[ -t 2 ]] || return 0
  local label="${1:-$(msg spinner_running)}"
  (
    local frames
    if (( _UNICODE )); then
      frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    else
      frames=('|' '/' '-' '\')
    fi
    local i=0
    while true; do
      printf '\r  %b%s %s%b' "$C5" "${frames[$i]}" "$label" "$RST" >&2
      i=$(( (i+1) % ${#frames[@]} ))
      sleep 0.1
    done
  ) &
  _SPINNER_PID=$!
  disown "$_SPINNER_PID" 2>/dev/null || true
}

spinner_stop() {
  [[ -n "${_SPINNER_PID:-}" ]] || return 0
  kill "$_SPINNER_PID" 2>/dev/null || true
  wait "$_SPINNER_PID" 2>/dev/null || true
  _SPINNER_PID=""
  printf '\r%*s\r' 80 '' >&2
}

# ── Progress bar ───────────────────────────────────────────────────────────
progress_bar() {
  (( QUIET_MODE==1 )) && return 0
  [[ -t 2 ]] || return 0
  local current="$1" total="$2" label="${3:-}"
  local width=40 pct filled empty bar
  (( total == 0 )) && total=1
  pct=$(( current * 100 / total ))
  filled=$(( current * width / total ))
  empty=$(( width - filled ))
  if (( _UNICODE )); then
    bar="$(printf '%*s' "$filled" '' | tr ' ' '█')$(printf '%*s' "$empty" '' | tr ' ' '░')"
  else
    bar="$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' "$empty" '' | tr ' ' '.')"
  fi
  printf '\r  %b%s%b %3d%% [%d/%d] %s' "$C2" "$bar" "$RST" "$pct" "$current" "$total" "$label" >&2
  (( current == total )) && printf '\n' >&2
}

# ── Module header  ~*~ Retro Cartoon Box ~*~ ──────────────────────────────
module_header() {
  local title="$1"
  (( QUIET_MODE==1 )) && return 0
  local len=${#title}
  local pad=$(( len + 6 ))
  local border
  border="$(printf "%${pad}s" '' | sed "s/ /$(_box_h)/g")"
  echo
  printf '%b%s%s%s%b\n' "$C6" "$(_box_tl)" "$border" "$(_box_tr)" "$RST"
  printf '%b%s  %b%s %s%b  %b%s%b\n' "$C6" "$(_box_v)" "${BOLD}${W}" "$(_arrow)" "$title" "$RST" "$C6" "$(_box_v)" "$RST"
  printf '%b%s%s%s%b\n' "$C6" "$(_box_bl)" "$border" "$(_box_br)" "$RST"
}

# ── Status / messaging ────────────────────────────────────────────────────
status() {
  local level="$1"; shift
  local label color
  case "$level" in
    ok)   label="$(msg status_ok)";   color="$G" ;;
    warn) label="$(msg status_warn)"; color="$Y" ;;
    err)  label="$(msg status_err)";  color="$R" ;;
    info) label="$(msg status_info)"; color="$C" ;;
    *)    label="$level";             color="$W" ;;
  esac
  printf '%b[%s]%b %s\n' "$color" "$label" "$RST" "$*"
}

die() { status err "$*"; exit 1; }

prompt() {
  local message="$1" default="${2:-}" value=""
  if [[ -n "$default" ]]; then
    read -r -p "$message [$default]: " value
    printf '%s' "${value:-$default}"
  else
    read -r -p "$message: " value
    printf '%s' "$value"
  fi
}

confirm() {
  local q="$1" ans=""
  (( AUTO_CONFIRM==1 )) && return 0
  read -r -p "$q [y/N]: " ans
  [[ "$ans" =~ ^([sS][iI]?|[yY][eE]?[sS]?)$ ]]
}

pause() {
  (( QUIET_MODE==1 || NON_INTERACTIVE==1 )) && return 0
  read -r -p "$(msg press_enter)" _
}

# ── Menu select ────────────────────────────────────────────────────────────
menu_select() {
  local title="$1"; shift
  local opts=("$@")
  echo
  module_header "$title"
  local i=1
  for opt in "${opts[@]}"; do
    printf '   %b[%2d]%b %s\n' "$C2" "$i" "$RST" "$opt"
    ((i++))
  done
  echo
  while true; do
    read -r -p "  $(_arrow) " MENU_CHOICE
    if [[ "$MENU_CHOICE" =~ ^[0-9]+$ ]] && (( MENU_CHOICE >= 1 && MENU_CHOICE <= ${#opts[@]} )); then
      return 0
    fi
    status warn "$(msg choice_invalid)"
  done
}

# ── Categorized menu select (grouped main menu) ───────────────────────────
menu_select_categorized() {
  local title="$1"; shift
  local -a items=("$@")
  local idx=1 item
  echo
  module_header "$title"
  for item in "${items[@]}"; do
    if [[ "$item" == ---* ]]; then
      local cat_name="${item#---}"
      printf '  %b%s %s %s%b\n' "${DIM}${C5}" "$(_box_h)$(_box_h)" "$cat_name" "$(_box_h)$(_box_h)" "$RST"
    else
      printf '   %b[%2d]%b %s\n' "$C2" "$idx" "$RST" "$item"
      ((idx++))
    fi
  done
  echo
  local choice_count=$((idx - 1))
  while true; do
    read -r -p "  $(_arrow) " MENU_CHOICE
    if [[ "$MENU_CHOICE" =~ ^[0-9]+$ ]] && (( MENU_CHOICE >= 1 && MENU_CHOICE <= choice_count )); then
      return 0
    fi
    status warn "$(msg choice_invalid)"
  done
}

# ── Teach box  ~*~ Full bordered info panel ~*~ ───────────────────────────
teach_box() {
  local title="$1" what="$2" when="$3" avoid="$4" next="$5"
  [[ "$TEACH_MODE" == "off" ]] && return 0
  (( QUIET_MODE==1 )) && return 0
  local w=76
  local hbar
  hbar="$(printf "%${w}s" '' | sed "s/ /$(_box_h)/g")"
  echo
  printf '%b%s%s%s%b\n' "$M" "$(_box_tl)" "$hbar" "$(_box_tr)" "$RST"
  printf '%b%s %b%-*s%b%b%s%b\n' "$M" "$(_box_v)" "${BOLD}${W}" "$((w-1))" "$title" "$RST" "$M" "$(_box_v)" "$RST"
  printf '%b%s%s%s%b\n' "$M" "$(_box_lj)" "$hbar" "$(_box_rj)" "$RST"
  printf '%b%s %b%-16s%b%-*s%b%s%b\n' "$M" "$(_box_v)" "${C}" "$(msg teach_what)"  "$RST" "$((w-17))" "$what"  "$M" "$(_box_v)" "$RST"
  printf '%b%s %b%-16s%b%-*s%b%s%b\n' "$M" "$(_box_v)" "${G}" "$(msg teach_when)"  "$RST" "$((w-17))" "$when"  "$M" "$(_box_v)" "$RST"
  printf '%b%s %b%-16s%b%-*s%b%s%b\n' "$M" "$(_box_v)" "${R}" "$(msg teach_avoid)" "$RST" "$((w-17))" "$avoid" "$M" "$(_box_v)" "$RST"
  printf '%b%s %b%-16s%b%-*s%b%s%b\n' "$M" "$(_box_v)" "${Y}" "$(msg teach_next)"  "$RST" "$((w-17))" "$next"  "$M" "$(_box_v)" "$RST"
  if [[ "$TEACH_MODE" == "deep" ]]; then
    printf '%b%s%s%s%b\n' "$M" "$(_box_lj)" "$hbar" "$(_box_rj)" "$RST"
    printf '%b%s %b%-*s%b%b%s%b\n' "$M" "$(_box_v)" "${DIM}" "$((w-1))" "$(pick_lang 'Consejo: valida primero, documenta la evidencia y solo despues profundiza.' 'Tip: validate first, document the evidence, and only then go deeper.')" "$RST" "$M" "$(_box_v)" "$RST"
  fi
  printf '%b%s%s%s%b\n' "$M" "$(_box_bl)" "$hbar" "$(_box_br)" "$RST"
}

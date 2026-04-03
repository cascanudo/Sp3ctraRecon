#!/usr/bin/env bash
# shellcheck disable=SC2034

APP_NAME="Sp3ctraRecon"
APP_SLUG="sp3ctrarecon"
VERSION="3.0.0"

LANG_UI="es"
TEACH_MODE="normal"
PROFILE="webapp"
PROFILE_THREADS=35
PROFILE_RATE=150
PROFILE_STEALTH="balanced"
PROFILE_TIMEOUT=180

TARGET=""
TARGET_KIND=""
DOMAIN=""
URL_BASE=""
TARGET_HOST=""
TARGET_PORT=""
DEFAULT_SCHEME=""
OUTPUT_DIR=""
HIST_FILE=""
REPORT_FILE=""
FINDINGS_FILE=""
ASSETS_FILE=""
SUMMARY_JSON=""
SESSION_ID=""
START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
ROOT_DIR="${SP3CTRA_ROOT}"
PROFILE_DIR="${SP3CTRA_ROOT}/profiles"

AUTO_CONFIRM=0
QUIET_MODE=0
NON_INTERACTIVE=0
MENU_CHOICE=""
CUSTOM_OUTPUT_DIR=""
SELF_CHECK_ONLY=0
LIST_MODULES_ONLY=0
LIST_PROFILES_ONLY=0
SHOW_VERSION_ONLY=0
MODULES_RAW=""
LANG_EXPLICIT=0
TEACH_EXPLICIT=0
PROFILE_EXPLICIT=0
REPORT_HTML=""
REPORT_FINALIZED=0

SUPPORTED_PROFILES=(learning webapp bugbounty internal ctf passive)
SUPPORTED_MODULES=(passive_osint subdomains dns live_hosts network web_fingerprint content_discovery params_js ssl cms services screenshots cloud headers emails cors favicon)
DEFAULT_WEB_WORDLISTS=(/usr/share/seclists/Discovery/Web-Content/common.txt /usr/share/dirb/wordlists/common.txt /usr/share/wordlists/dirb/common.txt)
KEY_TOOLS=(subfinder assetfinder amass theHarvester whois dig dnsx httpx nmap rustscan naabu whatweb nuclei ffuf feroxbuster waybackurls gau katana openssl sslscan wpscan joomscan enum4linux-ng smbclient snmpwalk showmount rpcinfo gowitness crosslinked curl)
CORE_REQUIRED_TOOLS=(python3 awk sed grep sort head tail wc cp mv)
CORE_OPTIONAL_TOOLS=(timeout readlink)

declare -a EXEC_HISTORY=()
declare -a MODULES=()
declare -A TOOL_STATUS=()
declare -A I18N=()

autoload_runtime_log() {
  if [[ -n "${OUTPUT_DIR:-}" ]]; then
    printf '%s' "${OUTPUT_DIR}/logs/runtime.log"
  else
    printf '%s' "${ROOT_DIR}/sp3ctrarecon_runtime.log"
  fi
}

on_error() {
  local line="$1" rc="$2"
  local logfile
  logfile="$(autoload_runtime_log)"
  mkdir -p "$(dirname "$logfile")" 2>/dev/null || true
  printf '%s\tline=%s\trc=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line" "$rc" >> "$logfile" 2>/dev/null || true
}

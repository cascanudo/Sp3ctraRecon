#!/usr/bin/env bash

safe_file_name() {
  local s="$1"
  s="${s//[^[:alnum:]._-]/_}"
  while [[ "$s" == *"__"* ]]; do
    s="${s//__/_}"
  done
  printf '%s' "${s#_}"
}

ensure_dir() {
  mkdir -p "$1"
}

csv_escape() {
  local s="$1"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

validate_ui_config() {
  [[ "$LANG_UI" =~ ^(es|en)$ ]] || die "$(msg runtime_lang_invalid): ${LANG_UI}"
  [[ "$TEACH_MODE" =~ ^(off|normal|deep)$ ]] || die "$(msg runtime_teach_invalid): ${TEACH_MODE}"
}

load_profile() {
  local file="${PROFILE_DIR}/${PROFILE}.conf"
  [[ -f "$file" ]] || die "$(msg runtime_profile_invalid): ${PROFILE}"

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    key="$(trim_whitespace "$key")"
    value="$(trim_whitespace "$value")"
    value="${value#\"}"
    value="${value%\"}"

    case "$key" in
      PROFILE_THREADS|PROFILE_RATE|PROFILE_TIMEOUT)
        [[ "$value" =~ ^[0-9]+$ ]] || die "$(pick_lang 'Valor numerico invalido en perfil' 'Invalid numeric value in profile'): ${key}"
        printf -v "$key" '%s' "$value"
        ;;
      PROFILE_STEALTH)
        [[ "$value" =~ ^(quiet|balanced|aggressive)$ ]] || die "$(pick_lang 'Valor de stealth invalido en perfil' 'Invalid stealth value in profile'): ${value}"
        PROFILE_STEALTH="$value"
        ;;
      *)
        die "$(pick_lang 'Clave invalida en perfil' 'Invalid key in profile'): ${key}"
        ;;
    esac
  done < "$file"
}

validate_execution_config() {
  validate_ui_config
  is_supported_profile "$PROFILE" || die "$(msg runtime_profile_invalid): ${PROFILE}"
  validate_modules_or_die
  load_profile
}

build_session_dir_name() {
  local base_target
  base_target="$(safe_file_name "${TARGET:-unknown}")"
  printf '%s' "${APP_SLUG}_${base_target}_${SESSION_ID}"
}

create_session() {
  SESSION_ID="$(date +%Y%m%d_%H%M%S)"

  local output_base
  output_base="${CUSTOM_OUTPUT_DIR:-$ROOT_DIR}"
  ensure_dir "$output_base"

  OUTPUT_DIR="${output_base}/$(build_session_dir_name)"
  while [[ -e "$OUTPUT_DIR" ]]; do
    SESSION_ID="${SESSION_ID}_1"
    OUTPUT_DIR="${output_base}/$(build_session_dir_name)"
  done

  mkdir -p \
    "${OUTPUT_DIR}/logs" \
    "${OUTPUT_DIR}/raw/network" \
    "${OUTPUT_DIR}/raw/dns" \
    "${OUTPUT_DIR}/raw/subdomains" \
    "${OUTPUT_DIR}/raw/livehosts" \
    "${OUTPUT_DIR}/raw/web" \
    "${OUTPUT_DIR}/raw/content" \
    "${OUTPUT_DIR}/raw/params" \
    "${OUTPUT_DIR}/raw/ssl" \
    "${OUTPUT_DIR}/raw/cms" \
    "${OUTPUT_DIR}/raw/osint" \
    "${OUTPUT_DIR}/raw/services" \
    "${OUTPUT_DIR}/raw/screenshots" \
    "${OUTPUT_DIR}/raw/cloud" \
    "${OUTPUT_DIR}/summary/network" \
    "${OUTPUT_DIR}/summary/dns" \
    "${OUTPUT_DIR}/summary/subdomains" \
    "${OUTPUT_DIR}/summary/livehosts" \
    "${OUTPUT_DIR}/summary/web" \
    "${OUTPUT_DIR}/summary/content" \
    "${OUTPUT_DIR}/summary/params" \
    "${OUTPUT_DIR}/summary/ssl" \
    "${OUTPUT_DIR}/summary/cms" \
    "${OUTPUT_DIR}/summary/osint" \
    "${OUTPUT_DIR}/summary/services" \
    "${OUTPUT_DIR}/summary/screenshots" \
    "${OUTPUT_DIR}/summary/cloud" \
    "${OUTPUT_DIR}/raw/headers" \
    "${OUTPUT_DIR}/raw/emails" \
    "${OUTPUT_DIR}/raw/cors" \
    "${OUTPUT_DIR}/raw/favicon" \
    "${OUTPUT_DIR}/summary/headers" \
    "${OUTPUT_DIR}/summary/emails" \
    "${OUTPUT_DIR}/summary/cors" \
    "${OUTPUT_DIR}/summary/favicon" \
    "${OUTPUT_DIR}/tmp" \
    "${OUTPUT_DIR}/reports"

  HIST_FILE="${OUTPUT_DIR}/logs/COMMAND_HISTORY.tsv"
  REPORT_FILE="${OUTPUT_DIR}/reports/RECON_REPORT.md"
  REPORT_HTML="${OUTPUT_DIR}/reports/RECON_REPORT.html"
  FINDINGS_FILE="${OUTPUT_DIR}/reports/FINDINGS.md"
  ASSETS_FILE="${OUTPUT_DIR}/reports/ASSETS.csv"
  SUMMARY_JSON="${OUTPUT_DIR}/reports/SUMMARY.json"
  REPORT_FINALIZED=0

  printf 'start_ts\tmodule\tdescription\trc\tduration_s\toutfile\tcommand\n' > "$HIST_FILE"
  {
    echo "# ${APP_NAME} v${VERSION} - $(msg report_title)"
    echo
    echo '| Campo | Valor |'
    echo '|---|---|'
    printf '| Objetivo | `%s` |\n' "$TARGET"
    printf '| Tipo | `%s` |\n' "$TARGET_KIND"
    printf '| Dominio | `%s` |\n' "${DOMAIN:-N/A}"
    printf '| URL base | `%s` |\n' "${URL_BASE:-N/A}"
    printf '| Perfil | `%s` |\n' "$PROFILE"
    printf '| Idioma | `%s` |\n' "$LANG_UI"
    printf '| Teach mode | `%s` |\n' "$TEACH_MODE"
    printf '| Inicio | `%s` |\n' "$START_TS"
    if ((${#MODULES[@]} > 0)); then
      printf '| %s | `%s` |\n' "$(msg modules_selected)" "$(IFS=,; echo "${MODULES[*]}")"
    fi
    echo
  } > "$REPORT_FILE"
  {
    echo "# $(msg findings_title)"
    echo
  } > "$FINDINGS_FILE"
  echo 'kind,value,source,notes' > "$ASSETS_FILE"
}

append_asset() {
  printf '%s,%s,%s,%s\n' \
    "$(csv_escape "$1")" \
    "$(csv_escape "$2")" \
    "$(csv_escape "$3")" \
    "$(csv_escape "$4")" >> "$ASSETS_FILE"
}

register_exec() {
  EXEC_HISTORY+=("$1|$2|$3|$4|$5|$6|$7")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" >> "$HIST_FILE"
}

render_cmd() {
  local out="" arg
  for arg in "$@"; do
    printf -v out '%s %q' "$out" "$arg"
  done
  printf '%s' "${out# }"
}

_run_common() {
  local module="$1" desc="$2" outfile="$3" rendered="$4"
  local rc="$5" dur="$6" stderr_file="$7" ts="$8"
  register_exec "$ts" "$module" "$desc" "$rc" "$dur" "$outfile" "$rendered"
  if (( rc == 0 )); then
    status ok "$(msg execution_done): $outfile"
  else
    status warn "$(msg return_code_warn) ${rc}. $(msg check_label): $stderr_file"
  fi
  return "$rc"
}

run_cmd() {
  local module="$1" desc="$2" outfile="$3"
  shift 3
  local -a cmd=("$@")
  local rendered ts stderr_file
  rendered="$(render_cmd "${cmd[@]}")"
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  stderr_file="${outfile}.stderr.log"

  ensure_dir "$(dirname "$outfile")"
  status info "$(msg command_label):"
  echo -e "${DIM}${rendered}${RST}"
  if (( NON_INTERACTIVE == 0 )) && ! confirm "$(msg confirm_run)"; then
    register_exec "$ts" "$module" "$desc" 2 0 "$outfile" "$rendered"
    status info "$(msg cmd_saved_only)"
    return 2
  fi

  local typ rc start end dur errexit_set=0
  typ="$(type -t "${cmd[0]}" 2>/dev/null || true)"
  local -a exec_cmd=("${cmd[@]}")
  if [[ "$typ" == file ]] && command -v timeout >/dev/null 2>&1; then
    exec_cmd=(timeout --signal=TERM "${PROFILE_TIMEOUT}s" "${cmd[@]}")
  fi

  spinner_start "$desc"
  start="$(date +%s)"
  [[ $- == *e* ]] && errexit_set=1
  set +e
  "${exec_cmd[@]}" > "$outfile" 2> "$stderr_file"
  rc=$?
  (( errexit_set == 1 )) && set -e
  end="$(date +%s)"
  dur=$((end - start))
  spinner_stop
  _run_common "$module" "$desc" "$outfile" "$rendered" "$rc" "$dur" "$stderr_file" "$ts"
}

run_block() {
  local module="$1" desc="$2" outfile="$3" fn="$4"
  shift 4
  local rendered ts stderr_file
  rendered="$(render_cmd "$fn" "$@")"
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  stderr_file="${outfile}.stderr.log"

  ensure_dir "$(dirname "$outfile")"
  status info "$(msg command_label):"
  echo -e "${DIM}${rendered}${RST}"
  if (( NON_INTERACTIVE == 0 )) && ! confirm "$(msg confirm_run)"; then
    register_exec "$ts" "$module" "$desc" 2 0 "$outfile" "$rendered"
    status info "$(msg cmd_saved_only)"
    return 2
  fi

  local rc start end dur errexit_set=0
  spinner_start "$desc"
  start="$(date +%s)"
  [[ $- == *e* ]] && errexit_set=1
  set +e
  "$fn" "$@" > "$outfile" 2> "$stderr_file"
  rc=$?
  (( errexit_set == 1 )) && set -e
  end="$(date +%s)"
  dur=$((end - start))
  spinner_stop
  _run_common "$module" "$desc" "$outfile" "$rendered" "$rc" "$dur" "$stderr_file" "$ts"
}

have_tool() {
  command -v "$1" >/dev/null 2>&1
}

detect_tools() {
  local t
  for t in "${KEY_TOOLS[@]}"; do
    have_tool "$t" && TOOL_STATUS["$t"]=yes || TOOL_STATUS["$t"]=no
  done
}

print_tool_status_list() {
  local color label tool
  for tool in "$@"; do
    if have_tool "$tool"; then
      color="$G"
      label="yes"
    else
      color="$Y"
      label="no"
    fi
    printf '  %-16s %b%s%b\n' "$tool" "$color" "$label" "$RST"
  done
}

tool_summary() {
  (( QUIET_MODE==1 )) && return 0
  echo
  module_header "$(msg tools_quick)"
  local col=0 tool color symbol
  for tool in "${KEY_TOOLS[@]}"; do
    if have_tool "$tool"; then
      color="$G"; symbol="$(_bullet)"
    else
      color="$Y"; symbol="o"
    fi
    printf '  %b%s%b %-14s' "$color" "$symbol" "$RST" "$tool"
    (( ++col % 4 == 0 )) && echo
  done
  (( col % 4 != 0 )) && echo
}

best_wordlist_web() {
  local wl
  for wl in "${DEFAULT_WEB_WORDLISTS[@]}"; do
    if [[ -f "$wl" ]]; then
      printf '%s' "$wl"
      return 0
    fi
  done
  return 1
}

dedupe_file() {
  [[ -s "$1" ]] && sort -u "$1" -o "$1"
  return 0
}

subdomains_file() {
  printf '%s' "${OUTPUT_DIR}/summary/subdomains/subdomains_all.txt"
}

network_ports_file() {
  printf '%s' "${OUTPUT_DIR}/summary/network/open_ports_unique.txt"
}

services_file() {
  printf '%s' "${OUTPUT_DIR}/summary/network/open_services.txt"
}

technologies_file() {
  printf '%s' "${OUTPUT_DIR}/summary/web/technologies.txt"
}

alive_urls_file() {
  printf '%s' "${OUTPUT_DIR}/summary/livehosts/alive_urls.txt"
}

interesting_paths_file() {
  printf '%s' "${OUTPUT_DIR}/summary/content/interesting_paths.tsv"
}

prioritized_endpoints_file() {
  printf '%s' "${OUTPUT_DIR}/summary/params/prioritized_endpoints.txt"
}

emails_file() {
  printf '%s' "${OUTPUT_DIR}/summary/emails/emails_all.txt"
}

is_port_open() {
  local port="$1" file
  file="$(network_ports_file)"
  [[ -s "$file" ]] || return 1
  grep -Eq "^${port}/(tcp|udp)$|^${port}$" "$file"
}

has_any_open_port() {
  local p
  for p in "$@"; do
    is_port_open "$p" && return 0
  done
  return 1
}

tech_contains() {
  local pat="$1" file
  file="$(technologies_file)"
  [[ -s "$file" ]] || return 1
  grep -Eiq "$pat" "$file"
}

ensure_network_context() {
  [[ -s "$(network_ports_file)" ]]
}

ensure_alive_context() {
  [[ -s "$(alive_urls_file)" ]]
}

ensure_targets_for_web() {
  local out="$1"
  ensure_dir "$(dirname "$out")"

  if [[ -s "$(alive_urls_file)" ]]; then
    cp "$(alive_urls_file)" "$out"
  elif [[ -n "$DOMAIN" && -s "$(subdomains_file)" ]]; then
    cp "$(subdomains_file)" "$out"
  elif [[ "$TARGET_KIND" == url && -n "$URL_BASE" ]]; then
    printf '%s\n' "$URL_BASE" > "$out"
  elif [[ -n "$DOMAIN" ]]; then
    printf '%s\n' "$DOMAIN" > "$out"
  elif [[ "$TARGET_KIND" == ip && -n "$TARGET_HOST" ]]; then
    printf '%s\n' "$TARGET_HOST" > "$out"
  else
    : > "$out"
  fi
}

dig_basic_records() {
  local d="$1" rt
  for rt in A AAAA MX TXT NS CNAME; do
    echo ">>> ${rt}"
    dig +short "$d" "$rt"
    echo
  done
}

openssl_collect_cert() {
  echo | openssl s_client -connect "$1:$2" -servername "$1" 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
}

run_whatweb_targets() {
  local targets="$1" out="$2" url
  : > "$out"
  while IFS= read -r url; do
    [[ -n "$url" ]] || continue
    echo "### ${url}" >> "$out"
    whatweb -a 3 "$url" >> "$out" 2>> "${out}.stderr.log" || true
    echo >> "$out"
  done < "$targets"
}

extract_ports_from_scan_output() {
  grep -E '^[0-9]+/(tcp|udp)[[:space:]]+open' "$1" | awk '{print $1}' | sort -u > "$2" 2>/dev/null || true
}

extract_services_from_scan_output() {
  grep -E '^[0-9]+/(tcp|udp)[[:space:]]+open' "$1" > "$2" 2>/dev/null || true
}

extract_alive_urls_from_httpx_json() {
  python3 - <<PY > "$2" 2>/dev/null
import json
seen=set()
for line in open(${1@Q}, encoding="utf-8", errors="ignore"):
    line=line.strip()
    if not line:
        continue
    try:
        obj=json.loads(line)
    except Exception:
        continue
    value=obj.get("url") or obj.get("input") or ""
    if value and value not in seen:
        seen.add(value)
        print(value)
PY
}

extract_httpx_enrichment() {
  python3 - <<PY > "${OUTPUT_DIR}/summary/livehosts/httpx_enriched.tsv" 2>/dev/null
import json
print("url\tstatus\ttitle\ttech\twebserver\tip\tcname\tcdn")
for line in open(${1@Q}, encoding="utf-8", errors="ignore"):
    line=line.strip()
    if not line:
        continue
    try:
        obj=json.loads(line)
    except Exception:
        continue
    tech=obj.get("tech")
    if isinstance(tech, list):
        tech=", ".join(tech)
    print("\t".join([
        str(obj.get("url") or obj.get("input") or ""),
        str(obj.get("status_code") or ""),
        str((obj.get("title") or "")).replace("\t", " "),
        str(tech or "").replace("\t", " "),
        str(obj.get("webserver") or ""),
        str(obj.get("host") or obj.get("ip") or ""),
        str(obj.get("cname") or ""),
        str(obj.get("cdn_name") or ""),
    ]))
PY
}

extract_technologies_from_httpx_json() {
  python3 - <<PY > "${2}.tmp" 2>/dev/null
import json
seen=set()
for line in open(${1@Q}, encoding="utf-8", errors="ignore"):
    line=line.strip()
    if not line:
        continue
    try:
        obj=json.loads(line)
    except Exception:
        continue
    tech=obj.get("tech") or []
    if isinstance(tech, str):
        tech=[tech]
    for item in tech:
        item=str(item).strip()
        if item and item.lower() not in seen:
            seen.add(item.lower())
            print(item)
PY

  if [[ -s "${2}.tmp" ]]; then
    if [[ -s "$2" ]]; then
      cat "${2}.tmp" >> "$2"
      dedupe_file "$2"
      rm -f "${2}.tmp"
    else
      mv "${2}.tmp" "$2"
    fi
  else
    rm -f "${2}.tmp"
  fi
}

extract_technologies_from_whatweb() {
  grep -Evi '^(#|$)' "$1" \
    | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -Eo '\[[^]]+\]' \
    | tr ',' '\n' \
    | sed 's/^[[]//; s/[]]$//; s/^ *//; s/ *$//' \
    | awk 'length>0' \
    | sort -u > "$2" 2>/dev/null || true
}

collect_ffuf_findings() {
  local out
  out="$(interesting_paths_file)"
  ensure_dir "$(dirname "$out")"
  printf 'url\tstatus\tlength\twords\tlines\n' > "$out"
  python3 - <<PY > "${out}.tmp" 2>/dev/null
import json
import pathlib
keys=("admin","login","signin","dashboard","portal","backup",".bak",".zip",".env","config","swagger","graphql","api","debug")
for path in sorted(pathlib.Path(${OUTPUT_DIR@Q}, "raw", "content").glob("ffuf_*.json")):
    try:
        data=json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    except Exception:
        continue
    for item in data.get("results", []):
        url=str(item.get("url") or "")
        status=str(item.get("status") or "")
        low=url.lower()
        if url and (status in {"200","204","301","302","307","308","401","403"} or any(k in low for k in keys)):
            print("\t".join([
                url,
                status,
                str(item.get("length") or ""),
                str(item.get("words") or ""),
                str(item.get("lines") or ""),
            ]))
PY
  [[ -s "${out}.tmp" ]] && sort -u "${out}.tmp" >> "$out"
  rm -f "${out}.tmp"
}

collect_param_keywords() {
  grep -E '/(admin|login|signin|auth|api|graphql|swagger|debug|token|oauth|callback)|[?&](token|redirect|url|next|return|id|user|email)=' "$1" | sort -u > "$2" 2>/dev/null || true
}

record_lines_as_assets() {
  local kind="$1" file="$2" source="$3" notes="$4" line
  [[ -s "$file" ]] || return 0
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    append_asset "$kind" "$line" "$source" "$notes"
  done < "$file"
}

module_selected() {
  ((${#MODULES[@]} == 0)) && return 0
  local m
  for m in "${MODULES[@]}"; do
    [[ "$m" == "$1" ]] && return 0
  done
  return 1
}

run_selected_module() {
  local requested="$1" fn="$2" rc=0 errexit_set=0
  module_selected "$requested" || return 0

  [[ $- == *e* ]] && errexit_set=1
  set +e
  "$fn"
  rc=$?
  (( errexit_set == 1 )) && set -e

  if (( rc != 0 )); then
    status warn "$(pick_lang 'El modulo devolvio un codigo no esperado y el flujo continuara.' 'The module returned an unexpected code and the flow will continue.') ${requested} (rc=${rc})"
  fi
  return 0
}

list_modules() {
  echo "$(msg list_modules_title):"
  local m
  for m in "${SUPPORTED_MODULES[@]}"; do
    echo "  - $m"
  done
  echo
  echo "$(pick_lang 'Aliases utiles:' 'Useful aliases:')"
  cat <<ALIASES
  - osint, passive, passive-osint -> passive_osint
  - subs, subdomain -> subdomains
  - live, alive, hosts -> live_hosts
  - network, ports, scan -> network
  - web, fingerprint -> web_fingerprint
  - content, dirs, fuzz -> content_discovery
  - params, js, endpoints -> params_js
  - ssl, tls -> ssl
  - cms, wordpress, joomla -> cms
  - services, service, nonweb -> services
  - screenshots, shots, capture -> screenshots
  - headers, header, security-headers -> headers
  - emails, email, mail, correos -> emails
  - cors, cors-check -> cors
  - favicon, fav, favicon-hash -> favicon
ALIASES
}

list_profiles() {
  echo "$(msg list_profiles_title):"
  local p
  for p in "${SUPPORTED_PROFILES[@]}"; do
    echo "  - $p"
  done
}

self_check() {
  detect_tools
  echo
  hr
  echo -e "${W}${BOLD}$(msg self_check_title)${RST}"
  hr
  echo "$(pick_lang 'Dependencias internas requeridas:' 'Required core dependencies:')"
  print_tool_status_list "${CORE_REQUIRED_TOOLS[@]}"
  echo
  echo "$(pick_lang 'Dependencias internas opcionales:' 'Optional core dependencies:')"
  print_tool_status_list "${CORE_OPTIONAL_TOOLS[@]}"
  echo
  status info "$(msg self_check_summary)"
  tool_summary
  echo
  echo "$(msg self_check_tip)"
}

setup_target() {
  [[ -z "$TARGET" ]] && TARGET="$(prompt "$(msg target_prompt)")"
  validate_target_or_die
  normalize_url_base
  status ok "$(msg target_ok): ${TARGET} (${TARGET_KIND})"
  [[ -n "$DOMAIN" ]] && status info "$(msg base_domain): $DOMAIN"
  [[ -n "$URL_BASE" ]] && status info "$(msg base_url): $URL_BASE"
  return 0
}

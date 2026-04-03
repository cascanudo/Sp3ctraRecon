#!/usr/bin/env bash

trim_whitespace() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS='.' a
  read -r -a a <<<"$ip"
  local n
  for n in "${a[@]}"; do
    [[ "$n" =~ ^[0-9]+$ ]] || return 1
    (( n >= 0 && n <= 255 )) || return 1
  done
}

is_ipv6() {
  python3 - <<PY >/dev/null 2>&1
import ipaddress; ipaddress.IPv6Address(${1@Q})
PY
}

is_cidr() {
  python3 - <<PY >/dev/null 2>&1
import ipaddress; ipaddress.ip_network(${1@Q}, strict=False)
PY
}

is_domain() {
  [[ "$1" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$ ]]
}

is_url() {
  python3 - <<PY >/dev/null 2>&1
from urllib.parse import urlparse
u=urlparse(${1@Q}); assert u.scheme in ("http", "https") and u.netloc
PY
}

extract_host_from_url() {
  python3 - <<PY
from urllib.parse import urlparse; print(urlparse(${1@Q}).hostname or "")
PY
}

extract_port_from_url() {
  python3 - <<PY
from urllib.parse import urlparse
u=urlparse(${1@Q})
print(u.port or (443 if u.scheme == "https" else 80))
PY
}

extract_scheme_from_url() {
  python3 - <<PY
from urllib.parse import urlparse; print(urlparse(${1@Q}).scheme or "")
PY
}

is_supported_profile() {
  local x
  for x in "${SUPPORTED_PROFILES[@]}"; do
    [[ "$x" == "$1" ]] && return 0
  done
  return 1
}

canonical_module_name() {
  local m="$1"
  m="$(trim_whitespace "$m")"
  m="${m,,}"
  case "$m" in
    osint|passive|passive-osint|passive_osint) printf '%s' 'passive_osint' ;;
    subs|subdomain|subdomains) printf '%s' 'subdomains' ;;
    dns) printf '%s' 'dns' ;;
    live|alive|live-hosts|live_hosts|hosts) printf '%s' 'live_hosts' ;;
    network|ports|scan) printf '%s' 'network' ;;
    web|fingerprint|web-fingerprint|web_fingerprint) printf '%s' 'web_fingerprint' ;;
    content|content-discovery|content_discovery|dirs|fuzz) printf '%s' 'content_discovery' ;;
    params|js|params-js|params_js|endpoints) printf '%s' 'params_js' ;;
    ssl|tls) printf '%s' 'ssl' ;;
    cms|wordpress|joomla) printf '%s' 'cms' ;;
    services|service|nonweb|non-web) printf '%s' 'services' ;;
    screenshots|shots|capture|captures) printf '%s' 'screenshots' ;;
    cloud) printf '%s' 'cloud' ;;
    headers|header|security-headers|sec-headers) printf '%s' 'headers' ;;
    emails|email|mail|correos) printf '%s' 'emails' ;;
    cors|cors-check) printf '%s' 'cors' ;;
    favicon|fav|favicon-hash|favhash) printf '%s' 'favicon' ;;
    *) printf '%s' "$m" ;;
  esac
}

is_supported_module() {
  local x target
  target="$(canonical_module_name "$1")"
  for x in "${SUPPORTED_MODULES[@]}"; do
    [[ "$x" == "$target" ]] && return 0
  done
  return 1
}

validate_modules_or_die() {
  [[ -z "$MODULES_RAW" ]] && return 0

  local raw module canonical
  IFS=',' read -r -a raw <<<"$MODULES_RAW"
  MODULES=()
  for module in "${raw[@]}"; do
    canonical="$(canonical_module_name "$module")"
    [[ -n "$canonical" ]] || continue
    is_supported_module "$canonical" || die "$(msg modules_invalid): $module"
    MODULES+=("$canonical")
  done
  ((${#MODULES[@]} > 0)) || die "$(msg no_modules_selected)"

  local -a deduped=()
  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] && deduped+=("$item")
  done < <(printf '%s\n' "${MODULES[@]}" | awk '!seen[$0]++')
  MODULES=("${deduped[@]}")
}

detect_target_kind() {
  local t="$1"
  DOMAIN=""
  URL_BASE=""
  TARGET_HOST=""
  TARGET_PORT=""
  DEFAULT_SCHEME=""

  if is_url "$t"; then
    TARGET_KIND="url"
    URL_BASE="$t"
    TARGET_HOST="$(extract_host_from_url "$t")"
    TARGET_PORT="$(extract_port_from_url "$t")"
    DEFAULT_SCHEME="$(extract_scheme_from_url "$t")"
    is_domain "$TARGET_HOST" && DOMAIN="$TARGET_HOST"
  elif is_ipv4 "$t" || is_ipv6 "$t"; then
    TARGET_KIND="ip"
    TARGET_HOST="$t"
  elif is_cidr "$t"; then
    TARGET_KIND="cidr"
    TARGET_HOST="$t"
  elif is_domain "$t"; then
    TARGET_KIND="domain"
    DOMAIN="${t,,}"
    TARGET_HOST="$DOMAIN"
  else
    return 1
  fi
}

validate_target_or_die() {
  detect_target_kind "$TARGET" || die "$(msg invalid_target): $TARGET"
}

normalize_url_base() {
  if [[ "$TARGET_KIND" == url ]]; then
    return 0
  fi
  URL_BASE=""
  TARGET_PORT=""
  DEFAULT_SCHEME=""
}

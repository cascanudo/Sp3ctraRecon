#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SP3CTRA_ROOT="$ROOT_DIR"

source "$ROOT_DIR/lib/app.sh"
source "$ROOT_DIR/lib/i18n.sh"
source "$ROOT_DIR/lib/ui.sh"
source "$ROOT_DIR/lib/validators.sh"
source "$ROOT_DIR/lib/cli.sh"
source "$ROOT_DIR/lib/core.sh"
load_i18n

ok(){ "$@" || { echo "fallo: $*" >&2; exit 1; }; }
fail(){ if "$@"; then echo "debio fallar: $*" >&2; exit 1; fi; }
expect_fail(){ ! ( "$@" ); }
assert_eq(){ [[ "$1" == "$2" ]] || { printf 'expected=%s actual=%s\n' "$1" "$2" >&2; exit 1; }; }

ok is_ipv4 192.168.1.1
fail is_ipv4 999.1.1.1
ok is_ipv6 2001:db8::1
ok is_cidr 10.0.0.0/24
ok is_domain example.com
fail is_domain bad_domain
ok is_url https://example.com/test
fail is_url ftp://example.com
ok is_supported_profile webapp
fail is_supported_profile nope

TARGET=example.com
ok validate_target_or_die
assert_eq domain "$TARGET_KIND"
assert_eq example.com "$DOMAIN"
normalize_url_base
assert_eq "" "${URL_BASE}"
assert_eq "" "${TARGET_PORT}"
assert_eq "" "${DEFAULT_SCHEME}"

TARGET=https://app.example.com:8443/login
ok validate_target_or_die
assert_eq url "$TARGET_KIND"
assert_eq app.example.com "$TARGET_HOST"
assert_eq 8443 "$TARGET_PORT"
assert_eq https "$DEFAULT_SCHEME"
normalize_url_base
assert_eq https://app.example.com:8443/login "$URL_BASE"

TARGET=192.0.2.10
ok validate_target_or_die
assert_eq ip "$TARGET_KIND"
assert_eq 192.0.2.10 "$TARGET_HOST"
normalize_url_base
assert_eq "" "${URL_BASE}"

TARGET=2001:db8::1
ok validate_target_or_die
assert_eq ip "$TARGET_KIND"
assert_eq 2001:db8::1 "$TARGET_HOST"

TARGET=10.0.0.0/24
ok validate_target_or_die
assert_eq cidr "$TARGET_KIND"
assert_eq 10.0.0.0/24 "$TARGET_HOST"

ok is_supported_module osint
ok is_supported_module web
ok is_supported_module live
ok is_supported_module screenshots
ok is_supported_module headers
ok is_supported_module emails
ok is_supported_module cors
ok is_supported_module favicon
ok is_supported_module header
ok is_supported_module email
ok is_supported_module cors-check
ok is_supported_module fav
ok is_supported_module correos
fail is_supported_module nope

MODULES_RAW='osint,web,params,live,content,osint'
ok validate_modules_or_die
assert_eq 'passive_osint,web_fingerprint,params_js,live_hosts,content_discovery' "$(IFS=,; echo "${MODULES[*]}")"

MODULES_RAW='passive_osint, dns , web_fingerprint'
ok validate_modules_or_die
assert_eq 'passive_osint,dns,web_fingerprint' "$(IFS=,; echo "${MODULES[*]}")"

MODULES_RAW='invalid_module'
ok expect_fail validate_modules_or_die

ok expect_fail parse_args --bogus
ok expect_fail parse_args -t
ok expect_fail parse_args --profile
ok expect_fail parse_args --lang
ok expect_fail parse_args --teach
ok expect_fail parse_args --output-dir
ok expect_fail parse_args --modules

LANG_EXPLICIT=0
TEACH_EXPLICIT=0
PROFILE_EXPLICIT=0
ok parse_args --lang en --teach deep --profile passive --modules osint,dns --output-dir /tmp/sp3ctra-base --non-interactive -y -q
assert_eq en "$LANG_UI"
assert_eq deep "$TEACH_MODE"
assert_eq passive "$PROFILE"
assert_eq osint,dns "$MODULES_RAW"
assert_eq /tmp/sp3ctra-base "$CUSTOM_OUTPUT_DIR"
assert_eq 1 "$LANG_EXPLICIT"
assert_eq 1 "$TEACH_EXPLICIT"
assert_eq 1 "$PROFILE_EXPLICIT"
assert_eq 1 "$NON_INTERACTIVE"
assert_eq 1 "$AUTO_CONFIRM"
assert_eq 1 "$QUIET_MODE"

LANG_UI=es
TEACH_MODE=normal
PROFILE=webapp
MODULES_RAW='osint,dns'
ok validate_execution_config
assert_eq 'passive_osint,dns' "$(IFS=,; echo "${MODULES[*]}")"

custom_base="$(mktemp -d)"
TARGET=example.com
CUSTOM_OUTPUT_DIR="$custom_base"
ok validate_target_or_die
normalize_url_base
ok create_session
[[ "$OUTPUT_DIR" == "$custom_base"/sp3ctrarecon_* ]] || { echo "OUTPUT_DIR no usa la base esperada: $OUTPUT_DIR" >&2; exit 1; }
[[ "$OUTPUT_DIR" != "$custom_base" ]] || { echo "OUTPUT_DIR no debe reutilizar la base directamente" >&2; exit 1; }
[[ -f "$HIST_FILE" ]] || { echo "No se creo COMMAND_HISTORY.tsv" >&2; exit 1; }
[[ -f "$REPORT_FILE" ]] || { echo "No se creo RECON_REPORT.md" >&2; exit 1; }

echo 'Validators test completado.'

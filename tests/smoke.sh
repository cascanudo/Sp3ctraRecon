#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

chmod +x "${ROOT_DIR}/bin/sp3ctrarecon"
bash -n "${ROOT_DIR}/bin/sp3ctrarecon"
for f in "${ROOT_DIR}"/lib/*.sh "${ROOT_DIR}"/modules/*.sh "${ROOT_DIR}"/tests/*.sh "${ROOT_DIR}"/install.sh "${ROOT_DIR}"/uninstall.sh; do
  bash -n "$f"
done

help_out="$(mktemp)"
modules_out="$(mktemp)"
profiles_out="$(mktemp)"
selfcheck_out="$(mktemp)"

"${ROOT_DIR}/bin/sp3ctrarecon" --help >"$help_out"
"${ROOT_DIR}/bin/sp3ctrarecon" --version >/dev/null
"${ROOT_DIR}/bin/sp3ctrarecon" --list-modules >"$modules_out"
"${ROOT_DIR}/bin/sp3ctrarecon" --list-profiles >"$profiles_out"
"${ROOT_DIR}/bin/sp3ctrarecon" --self-check >"$selfcheck_out"

assert_file(){ [[ -f "$1" ]] || { echo "Falta archivo esperado: $1" >&2; exit 1; }; }
assert_not_grep(){ local pat="$1" file="$2"; if grep -Eiq "$pat" "$file"; then echo "Patron inesperado en $file: $pat" >&2; cat "$file" >&2; exit 1; fi; }
assert_grep(){ local pat="$1" file="$2"; grep -Eq "$pat" "$file" || { echo "No se encontro el patron en $file: $pat" >&2; cat "$file" >&2; exit 1; }; }

assert_grep 'osint, passive, passive-osint -> passive_osint' "$modules_out"
assert_grep 'live, alive, hosts -> live_hosts' "$modules_out"
assert_grep 'web, fingerprint -> web_fingerprint' "$modules_out"
assert_grep 'content, dirs, fuzz -> content_discovery' "$modules_out"
assert_grep 'params, js, endpoints -> params_js' "$modules_out"
assert_grep 'headers, header, security-headers -> headers' "$modules_out"
assert_grep 'emails, email, mail, correos -> emails' "$modules_out"
assert_grep 'cors, cors-check -> cors' "$modules_out"
assert_grep 'favicon, fav, favicon-hash -> favicon' "$modules_out"
assert_grep 'passive' "$profiles_out"
assert_grep '(Quick status of key tools|Estado rapido de herramientas clave)' "$selfcheck_out"
assert_grep '(Usage|Uso)' "$help_out"

find_session_dir() {
  local base="$1" path
  for path in "$base"/*; do
    [[ -d "$path" ]] || continue
    printf '%s' "$path"
    return 0
  done
  return 1
}

run_case() {
  local target="$1"
  local expected_kind="$2"
  local profile="$3"
  local base_outdir="$4"
  shift 4

  local stdout_file="${base_outdir}.stdout"
  local stderr_file="${base_outdir}.stderr"
  local -a cmd=("${ROOT_DIR}/bin/sp3ctrarecon" -t "$target" -p "$profile" --non-interactive -y -q -o "$base_outdir")
  if (($# > 0)); then
    cmd+=("$@")
  fi

  if ! "${cmd[@]}" >"$stdout_file" 2>"$stderr_file"; then
    echo "Smoke test fallo para target=$target profile=$profile" >&2
    cat "$stderr_file" >&2
    exit 1
  fi

  assert_not_grep 'command not found|syntax error|invalid module|traceback|Permission denied' "$stderr_file"

  local session_dir
  session_dir="$(find_session_dir "$base_outdir")" || {
    echo "No se encontro directorio de sesion dentro de $base_outdir" >&2
    exit 1
  }

  assert_file "$session_dir/reports/RECON_REPORT.md"
  assert_file "$session_dir/reports/RECON_REPORT.html"
  assert_file "$session_dir/reports/SUMMARY.json"
  assert_file "$session_dir/reports/FINDINGS.md"
  assert_file "$session_dir/reports/ASSETS.csv"
  assert_file "$session_dir/logs/COMMAND_HISTORY.tsv"

  assert_grep "\"target_kind\": \"$expected_kind\"" "$session_dir/reports/SUMMARY.json"
  assert_grep "\"profile\": \"$profile\"" "$session_dir/reports/SUMMARY.json"
  assert_grep '"counts": \{' "$session_dir/reports/SUMMARY.json"
  assert_grep '^# ' "$session_dir/reports/FINDINGS.md"
  assert_grep '^kind,value,source,notes$' "$session_dir/reports/ASSETS.csv"
  awk -F'\t' 'NR==1 { exit !($1=="start_ts" && $2=="module" && $3=="description" && $4=="rc" && $5=="duration_s" && $6=="outfile" && $7=="command") }' "$session_dir/logs/COMMAND_HISTORY.tsv" || {
    echo "COMMAND_HISTORY.tsv tiene un encabezado inesperado" >&2
    cat "$session_dir/logs/COMMAND_HISTORY.tsv" >&2
    exit 1
  }
  assert_grep '^## (Resumen de sesion|Session summary)$' "$session_dir/reports/RECON_REPORT.md"

  printf '%s' "$session_dir"
}

domain_base="$(mktemp -d)"
domain_session="$(run_case example.com domain passive "$domain_base")"
assert_grep '^## (OSINT Pasivo|Passive OSINT)$' "$domain_session/reports/RECON_REPORT.md"
assert_grep '^## DNS$' "$domain_session/reports/RECON_REPORT.md"
assert_grep '^## (JS y parametros|JS and parameters)$' "$domain_session/reports/RECON_REPORT.md"
[[ "$(wc -l < "$domain_session/reports/ASSETS.csv")" -ge 2 ]] || { echo "ASSETS.csv no tiene datos para domain" >&2; exit 1; }

url_base="$(mktemp -d)"
url_session="$(run_case https://app.example.com/login url passive "$url_base")"
assert_grep '^## (OSINT Pasivo|Passive OSINT)$' "$url_session/reports/RECON_REPORT.md"
[[ "$(wc -l < "$url_session/reports/ASSETS.csv")" -ge 2 ]] || { echo "ASSETS.csv no tiene datos para url" >&2; exit 1; }

ip_base="$(mktemp -d)"
ip_session="$(run_case 192.0.2.10 ip passive "$ip_base")"
assert_grep '^## (OSINT Pasivo|Passive OSINT)$' "$ip_session/reports/RECON_REPORT.md"

cidr_base="$(mktemp -d)"
cidr_session="$(run_case 10.0.0.0/24 cidr passive "$cidr_base")"
assert_grep '^## (OSINT Pasivo|Passive OSINT)$' "$cidr_session/reports/RECON_REPORT.md"

modules_base="$(mktemp -d)"
modules_session="$(run_case example.com domain passive "$modules_base" -m osint,dns)"
assert_grep '^## (OSINT Pasivo|Passive OSINT)$' "$modules_session/reports/RECON_REPORT.md"
assert_grep '^## DNS$' "$modules_session/reports/RECON_REPORT.md"
assert_not_grep '^## (Subdominios Descubiertos|Discovered Subdomains)$' "$modules_session/reports/RECON_REPORT.md"
assert_not_grep '^## (JS y parametros|JS and parameters)$' "$modules_session/reports/RECON_REPORT.md"
[[ "$(wc -l < "$modules_session/reports/ASSETS.csv")" -ge 2 ]] || { echo "ASSETS.csv no tiene datos para modules" >&2; exit 1; }

new_mods_base="$(mktemp -d)"
new_mods_session="$(run_case example.com domain passive "$new_mods_base" -m emails)"
assert_grep '^## (Correos electronicos|Email Harvesting)$' "$new_mods_session/reports/RECON_REPORT.md"
assert_grep '<html' "$new_mods_session/reports/RECON_REPORT.html"

passive_params_base="$(mktemp -d)"
passive_params_session="$(run_case example.com domain passive "$passive_params_base" -m params)"
assert_grep '^## (JS y parametros|JS and parameters)$' "$passive_params_session/reports/RECON_REPORT.md"
assert_not_grep 'katana' "$passive_params_session/logs/COMMAND_HISTORY.tsv"

copy_prefix="$(mktemp -d)"
copy_install_root="$(mktemp -d)/sp3ctra_copy"
bash "${ROOT_DIR}/install.sh" --copy --prefix "$copy_prefix" --install-root "$copy_install_root" >/dev/null
"$copy_prefix/bin/sp3ctrarecon" --version >/dev/null
PREFIX="$copy_prefix" INSTALL_ROOT="$copy_install_root" bash "${ROOT_DIR}/uninstall.sh" >/dev/null
[[ ! -e "$copy_prefix/bin/sp3ctrarecon" ]] || { echo "Wrapper de copy aun existe" >&2; exit 1; }
[[ ! -e "$copy_install_root" ]] || { echo "Instalacion de copy aun existe" >&2; exit 1; }

link_prefix="$(mktemp -d)"
link_install_root="$(mktemp -d)/sp3ctra_link"
mkdir -p "$link_install_root"
bash "${ROOT_DIR}/install.sh" --link --prefix "$link_prefix" >/dev/null
"$link_prefix/bin/sp3ctrarecon" --version >/dev/null
PREFIX="$link_prefix" INSTALL_ROOT="$link_install_root" bash "${ROOT_DIR}/uninstall.sh" >/dev/null
[[ ! -e "$link_prefix/bin/sp3ctrarecon" ]] || { echo "Wrapper de link aun existe" >&2; exit 1; }
[[ ! -e "$link_install_root" ]] || { echo "Instalacion de link aun existe" >&2; exit 1; }

echo 'Smoke test completado.'

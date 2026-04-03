#!/usr/bin/env bash

show_help() {
  if [[ "$LANG_UI" == en ]]; then
    cat <<HELP
${APP_NAME} v${VERSION}

$(msg help_title):
  $0 [options]

$(msg help_options):
  -t, --target VALUE         Target (IP, domain, URL, or CIDR)
  -l, --lang es|en           Interface language
  -p, --profile NAME         learning|webapp|bugbounty|internal|ctf|passive
      --teach MODE           off|normal|deep
  -m, --modules LIST         Comma-separated modules or aliases
      --list-modules         Print supported modules and aliases, then exit
      --list-profiles        Print supported profiles, then exit
      --self-check           Check core dependencies and tool availability
  -o, --output-dir PATH      Base directory for per-session output folders
  -y, --yes                  Auto-confirm executions
  -q, --quiet                Reduce banners and non-essential output
      --non-interactive      Run without menus
      --version              Show version and exit
  -h, --help                 Show help
HELP
  else
    cat <<HELP
${APP_NAME} v${VERSION}

$(msg help_title):
  $0 [opciones]

$(msg help_options):
  -t, --target VALUE         Objetivo (IP, dominio, URL o CIDR)
  -l, --lang es|en           Idioma de interfaz
  -p, --profile NAME         learning|webapp|bugbounty|internal|ctf|passive
      --teach MODE           off|normal|deep
  -m, --modules LIST         Lista de modulos o aliases separados por coma
      --list-modules         Imprime modulos y aliases soportados y sale
      --list-profiles        Imprime perfiles soportados y sale
      --self-check           Revisa dependencias internas y herramientas
  -o, --output-dir PATH      Directorio base para carpetas de sesion
  -y, --yes                  Auto-confirmar ejecuciones
  -q, --quiet                Reducir banners y salida no esencial
      --non-interactive      Ejecutar sin menus
      --version              Mostrar version y salir
  -h, --help                 Mostrar ayuda
HELP
  fi
}

require_value_arg() {
  local opt="$1"
  local value="${2-}"
  [[ -n "$value" ]] || die "$(pick_lang 'Falta un valor para' 'Missing value for'): $opt"
  REPLY="$value"
}

parse_args() {
  local value
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        TARGET="$value"
        shift 2
        ;;
      -l|--lang)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        LANG_UI="$value"
        LANG_EXPLICIT=1
        shift 2
        ;;
      -p|--profile)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        PROFILE="$value"
        PROFILE_EXPLICIT=1
        shift 2
        ;;
      --teach)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        TEACH_MODE="$value"
        TEACH_EXPLICIT=1
        shift 2
        ;;
      -m|--modules)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        MODULES_RAW="$value"
        shift 2
        ;;
      --list-modules)
        LIST_MODULES_ONLY=1
        shift
        ;;
      --list-profiles)
        LIST_PROFILES_ONLY=1
        shift
        ;;
      --self-check)
        SELF_CHECK_ONLY=1
        shift
        ;;
      --version)
        SHOW_VERSION_ONLY=1
        shift
        ;;
      -o|--output-dir)
        require_value_arg "$1" "${2-}"
        value="$REPLY"
        CUSTOM_OUTPUT_DIR="$value"
        shift 2
        ;;
      -y|--yes)
        AUTO_CONFIRM=1
        shift
        ;;
      -q|--quiet)
        QUIET_MODE=1
        shift
        ;;
      --non-interactive)
        NON_INTERACTIVE=1
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        die "$(pick_lang 'Argumento no reconocido' 'Unrecognized argument'): $1"
        ;;
    esac
  done
}

choose_language() {
  (( NON_INTERACTIVE == 1 || LANG_EXPLICIT == 1 )) && return 0
  menu_select "$(msg lang_prompt)" "Espanol" "English"
  [[ "$MENU_CHOICE" == 2 ]] && LANG_UI=en || LANG_UI=es
}

choose_teach_mode() {
  (( NON_INTERACTIVE == 1 || TEACH_EXPLICIT == 1 )) && return 0
  menu_select \
    "$(msg teach_prompt)" \
    "Off - $(pick_lang 'solo ejecutar' 'just run')" \
    "Normal - $(pick_lang 'explicar lo esencial' 'explain essentials')" \
    "Deep - $(pick_lang 'explicacion ampliada' 'deeper explanation')"
  case "$MENU_CHOICE" in
    1) TEACH_MODE=off ;;
    2) TEACH_MODE=normal ;;
    3) TEACH_MODE=deep ;;
  esac
}

choose_profile() {
  (( NON_INTERACTIVE == 1 || PROFILE_EXPLICIT == 1 )) && return 0
  menu_select \
    "$(msg profile_prompt)" \
    "$(pick_lang 'Aprendizaje - guiado y conservador' 'Learning - guided and conservative')" \
    "$(pick_lang 'Web App - foco en superficie web' 'Web App - focus on web surface')" \
    "$(pick_lang 'Bug Bounty - pasivo primero, validacion cuidadosa' 'Bug Bounty - passive first, careful validation')" \
    "$(pick_lang 'Interno / AD - servicios y entorno corporativo' 'Internal / AD - services and corporate environment')" \
    "$(pick_lang 'CTF / Laboratorio - velocidad alta' 'CTF / Lab - high speed')" \
    "$(pick_lang 'OSINT Pasivo - cero ruido directo' 'Passive OSINT - zero direct noise')"
  case "$MENU_CHOICE" in
    1) PROFILE=learning ;;
    2) PROFILE=webapp ;;
    3) PROFILE=bugbounty ;;
    4) PROFILE=internal ;;
    5) PROFILE=ctf ;;
    6) PROFILE=passive ;;
  esac
}

show_main_menu() {
  while true; do
    menu_select_categorized \
      "$(msg menu_main)" \
      "---$(msg category_recon)" \
      "$(msg menu_auto_recon)" \
      "$(msg menu_passive_osint)" \
      "$(msg menu_subdomains)" \
      "$(msg menu_dns)" \
      "$(msg menu_emails)" \
      "---$(msg category_web)" \
      "$(msg menu_live_hosts)" \
      "$(msg menu_web_fingerprint)" \
      "$(msg menu_headers)" \
      "$(msg menu_cors)" \
      "$(msg menu_favicon)" \
      "$(msg menu_content)" \
      "$(msg menu_params)" \
      "$(msg menu_ssl)" \
      "$(msg menu_cms)" \
      "---$(msg category_infra)" \
      "$(msg menu_network)" \
      "$(msg menu_services)" \
      "$(msg menu_screenshots)" \
      "$(msg menu_cloud)" \
      "---$(msg category_other)" \
      "$(msg menu_tools)" \
      "$(msg menu_finalize)"
    case "$MENU_CHOICE" in
      1) auto_recon ;;
      2) mod_passive_osint ;;
      3) mod_subdomains ;;
      4) mod_dns ;;
      5) mod_emails ;;
      6) mod_live_hosts ;;
      7) mod_web_fingerprint ;;
      8) mod_headers ;;
      9) mod_cors ;;
      10) mod_favicon ;;
      11) mod_content_discovery ;;
      12) mod_params_js ;;
      13) mod_ssl ;;
      14) mod_cms ;;
      15) mod_network ;;
      16) mod_services ;;
      17) mod_screenshots ;;
      18) mod_cloud ;;
      19) tool_summary; pause ;;
      20) finalize_report; break ;;
    esac
  done
}

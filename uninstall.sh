#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.local/share/sp3ctrarecon}"
BIN_DIR="${PREFIX}/bin"
TARGET_BIN="${BIN_DIR}/sp3ctrarecon"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' 'Uso: ./uninstall.sh [--prefix PATH] [--install-root PATH]'
}

require_value() {
  local opt="$1" val="${2-}"
  [[ -n "${val:-}" ]] || die "Falta valor para $opt"
}

require_absolute_path() {
  local label="$1" path="$2"
  [[ "$path" == /* || "$path" =~ ^[A-Za-z]:/ ]] || die "$label debe ser una ruta absoluta: $path"
}

ensure_safe_prefix() {
  local prefix="$1"
  require_absolute_path "PREFIX" "$prefix"
  [[ "$prefix" != "/" ]] || die 'PREFIX no puede ser /'
  [[ "$prefix" != "${ROOT_DIR}" ]] || die 'PREFIX no puede apuntar al repositorio fuente'
}

ensure_safe_install_root() {
  local install_root="$1"
  require_absolute_path "INSTALL_ROOT" "$install_root"
  case "$install_root" in
    "/"|"$HOME"|"$ROOT_DIR"|"$PREFIX"|"$BIN_DIR")
      die "INSTALL_ROOT no es seguro: $install_root"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      require_value "$1" "${2-}"
      PREFIX="$2"
      BIN_DIR="${PREFIX}/bin"
      TARGET_BIN="${BIN_DIR}/sp3ctrarecon"
      shift 2
      ;;
    --install-root)
      require_value "$1" "${2-}"
      INSTALL_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Argumento no reconocido: $1"
      ;;
  esac
done

ensure_safe_prefix "$PREFIX"
ensure_safe_install_root "$INSTALL_ROOT"

if [[ -e "$TARGET_BIN" || -L "$TARGET_BIN" ]]; then
  rm -f "$TARGET_BIN"
  echo "Wrapper eliminado: $TARGET_BIN"
else
  echo "No se encontro wrapper en: $TARGET_BIN"
fi

if [[ -e "$INSTALL_ROOT" ]]; then
  rm -rf "$INSTALL_ROOT"
  echo "Contenido instalado eliminado: $INSTALL_ROOT"
else
  echo "No se encontro contenido instalado en: $INSTALL_ROOT"
fi

#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.local/share/sp3ctrarecon}"
MODE="${MODE:-copy}"
BIN_DIR="${PREFIX}/bin"
TARGET_BIN="${BIN_DIR}/sp3ctrarecon"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' 'Uso: ./install.sh [--copy|--link] [--prefix PATH] [--install-root PATH]'
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
  [[ "$prefix" != "$ROOT_DIR" ]] || die 'PREFIX no puede apuntar al repositorio fuente'
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
    --copy)
      MODE=copy
      shift
      ;;
    --link)
      MODE=link
      shift
      ;;
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

case "$MODE" in
  copy|link) ;;
  *) die "MODE invalido: $MODE" ;;
esac

ensure_safe_prefix "$PREFIX"
ensure_safe_install_root "$INSTALL_ROOT"

mkdir -p "$BIN_DIR"
[[ -d "$TARGET_BIN" && ! -L "$TARGET_BIN" ]] && die "No se puede escribir sobre un directorio existente: $TARGET_BIN"

chmod +x "${ROOT_DIR}/bin/sp3ctrarecon"

if [[ "$MODE" == copy ]]; then
  rm -rf "$INSTALL_ROOT"
  mkdir -p "$(dirname "$INSTALL_ROOT")"
  cp -R "$ROOT_DIR" "$INSTALL_ROOT"
  chmod +x "${INSTALL_ROOT}/bin/sp3ctrarecon"
  cat > "$TARGET_BIN" <<WRAP
#!/usr/bin/env bash
exec "${INSTALL_ROOT}/bin/sp3ctrarecon" "\$@"
WRAP
  chmod +x "$TARGET_BIN"
  echo "Instalado en: $INSTALL_ROOT"
  echo "Wrapper creado en: $TARGET_BIN"
else
  if ln -sfn "${ROOT_DIR}/bin/sp3ctrarecon" "$TARGET_BIN" 2>/dev/null && [[ -L "$TARGET_BIN" ]]; then
    echo "Enlace simbolico creado en: $TARGET_BIN"
  else
    rm -f "$TARGET_BIN"
    cat > "$TARGET_BIN" <<WRAP
#!/usr/bin/env bash
exec "${ROOT_DIR}/bin/sp3ctrarecon" "\$@"
WRAP
    chmod +x "$TARGET_BIN"
    echo "Wrapper de link creado en: $TARGET_BIN"
  fi
  echo "Modo link: el repo original debe permanecer en su ubicacion actual."
fi

echo "Asegurate de tener ${BIN_DIR} en tu PATH."

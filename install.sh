#!/usr/bin/env bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Instalación
## ═══════════════════════════════════════════════════════════════════════════
## Instala dependencias básicas y delega la compilación en build.sh.
## Uso: ./install.sh [--skip-nim] [--skip-build] [--enable-sqlite] [--help]
## ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SKIP_NIM=false
SKIP_BUILD=false
ENABLE_SQLITE=false

print_header() {
  echo -e "${CYAN}"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "  CEO-Agents - Sistema de Agentes Evolutivos"
  echo "  Instalador v2.0"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo -e "${NC}"
}

print_step() {
  echo -e "${CYAN}▶ $1${NC}"
}

print_ok() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --skip-nim) SKIP_NIM=true ;;
      --skip-build) SKIP_BUILD=true ;;
      --enable-sqlite) ENABLE_SQLITE=true ;;
      --help|-h)
        echo "Uso: ./install.sh [opciones]"
        echo ""
        echo "Opciones:"
        echo "  --skip-nim       Omitir instalación de Nim"
        echo "  --skip-build     Omitir compilación final"
        echo "  --enable-sqlite  Compilar con soporte SQLite opcional"
        echo "  --help           Mostrar esta ayuda"
        exit 0
        ;;
      *)
        print_error "Argumento desconocido: $arg"
        exit 1
        ;;
    esac
  done
}

check_dependencies() {
  print_step "Verificando dependencias del sistema..."

  if ! command -v gcc >/dev/null 2>&1; then
    print_warn "gcc no encontrado. Instalando build-essential..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq
      sudo apt-get install -y -qq gcc g++ build-essential curl git
    else
      print_error "No se puede instalar gcc automáticamente en este sistema."
      exit 1
    fi
  fi
  print_ok "gcc disponible"

  if ! command -v curl >/dev/null 2>&1; then
    print_warn "curl no encontrado. Instalando..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq curl
  fi
  print_ok "curl disponible"
}

install_nim() {
  if [[ "$SKIP_NIM" == true ]]; then
    print_warn "Se omite la instalación de Nim por petición del usuario"
    return 0
  fi

  print_step "Verificando instalación de Nim..."

  if command -v nim >/dev/null 2>&1; then
    print_ok "Nim ya instalado: $(nim --version | head -1)"
    return 0
  fi

  if [ -f "$HOME/.nimble/bin/nim" ]; then
    export PATH="$HOME/.nimble/bin:$PATH"
    print_ok "Nim encontrado en PATH: $(nim --version | head -1)"
    return 0
  fi

  print_step "Instalando Nim vía choosenim..."
  CHOOSENIM_NO_ANALYTICS=1 curl -fsSL https://nim-lang.org/choosenim/init.sh | bash -s -- -y
  export PATH="$HOME/.nimble/bin:$PATH"

  if command -v nim >/dev/null 2>&1; then
    print_ok "Nim instalado correctamente: $(nim --version | head -1)"
  else
    print_error "Error al instalar Nim. Visita https://nim-lang.org/install.html"
    exit 1
  fi
}

build_project() {
  if [[ "$SKIP_BUILD" == true ]]; then
    print_warn "Se omite la compilación final"
    return 0
  fi

  print_step "Compilando proyecto..."
  if [[ "$ENABLE_SQLITE" == true ]]; then
    print_warn "SQLite opcional activado: asegúrate de tener db_connector/db_sqlite instalado"
    CEO_ENABLE_SQLITE_TOOLS=1 bash build.sh all
  else
    bash build.sh all
  fi
  print_ok "Proyecto compilado correctamente"
}

print_usage() {
  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  ✅ Instalación completada exitosamente${NC}"
  echo ""
  echo "  Comandos recomendados:"
  echo "    nimble buildCore"
  echo "    nimble buildExamples"
  echo "    nimble buildAPI"
  echo "    nimble runFunctional"
  echo ""
  echo "  Documentación: README.md | INSTALL.md | INDEX.md"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
}

main() {
  print_header
  parse_args "$@"
  check_dependencies
  install_nim
  cd "$(dirname "$0")"
  build_project
  print_usage
}

main "$@"

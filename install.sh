#!/bin/bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Instalación Rectificado
## ═══════════════════════════════════════════════════════════════════════════
## Instala todas las dependencias necesarias y configura el entorno para Nim 2.x.
## ═══════════════════════════════════════════════════════════════════════════

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  CEO-Agents - Sistema de Agentes Evolutivos"
    echo "  Instalador Rectificado v1.0"
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

# 1. Validación de Versión y Dependencias
check_dependencies() {
    print_step "Verificando dependencias del sistema..."

    if command -v nim >/dev/null; then
        NIM_VER=$(nim --version | head -n1 | cut -d' ' -f4)
        if [[ "$NIM_VER" < "2.0.0" ]]; then
            print_warn "Nim $NIM_VER detectado. Se requiere >= 2.0.0. Actualizando..."
            if command -v choosenim >/dev/null; then
                choosenim stable
            else
                print_step "Instalando Nim via choosenim..."
                curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y
            fi
        else
            print_ok "Nim $NIM_VER detectado (compatible)."
        fi
    else
        print_step "Nim no encontrado. Instalando..."
        curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y
    fi

    # 2. Persistencia de PATH
    SHELL_RC="$HOME/.bashrc"
    [[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

    if ! grep -q ".nimble/bin" "$SHELL_RC"; then
        echo 'export PATH="$HOME/.nimble/bin:$PATH"' >> "$SHELL_RC"
        print_ok "PATH actualizado en $SHELL_RC."
    fi

    export PATH="$HOME/.nimble/bin:$PATH"
}

build_project() {
    print_step "Iniciando Build de CEO-Agents..."
    chmod +x build.sh
    ./build.sh
}

print_usage() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Entorno configurado exitosamente!${NC}"
    echo ""
    echo "  Por favor, reinicia tu terminal o ejecuta:"
    echo "    source $SHELL_RC"
    echo ""
    echo "  Para ejecutar los ejemplos:"
    echo "    ./bin/example_integrated_ceo_stack"
    echo "═══════════════════════════════════════════════════════════════════════${NC}"
}

# Main
print_header
check_dependencies
build_project
print_usage

#!/usr/bin/env bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Instalación
## ═══════════════════════════════════════════════════════════════════════════
## Instala todas las dependencias necesarias y compila el proyecto.
## Uso: ./install.sh [--skip-nim] [--help]
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
    echo "  Instalador v1.0"
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

check_dependencies() {
    print_step "Verificando dependencias del sistema..."

    # Verificar gcc
    if ! command -v gcc &> /dev/null; then
        print_warn "gcc no encontrado. Instalando build-essential..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq gcc g++ build-essential
        elif command -v brew &> /dev/null; then
            xcode-select --install 2>/dev/null || true
        else
            print_error "No se puede instalar gcc automáticamente. Instálalo manualmente."
            exit 1
        fi
    fi
    print_ok "gcc disponible: $(gcc --version | head -1)"

    # Verificar curl
    if ! command -v curl &> /dev/null; then
        print_warn "curl no encontrado. Instalando..."
        sudo apt-get install -y -qq curl
    fi
    print_ok "curl disponible"
}

install_nim() {
    print_step "Verificando instalación de Nim..."

    if command -v nim &> /dev/null; then
        NIM_VERSION=$(nim --version | head -1)
        print_ok "Nim ya instalado: $NIM_VERSION"
        return 0
    fi

    # Verificar si está en ~/.nimble/bin
    if [ -f "$HOME/.nimble/bin/nim" ]; then
        export PATH="$HOME/.nimble/bin:$PATH"
        print_ok "Nim encontrado en ~/.nimble/bin: $(nim --version | head -1)"
        return 0
    fi

    print_step "Instalando Nim via choosenim..."
    CHOOSENIM_NO_ANALYTICS=1 curl https://nim-lang.org/choosenim/init.sh -sSf | bash -s -- -y

    export PATH="$HOME/.nimble/bin:$PATH"

    if command -v nim &> /dev/null; then
        print_ok "Nim instalado correctamente: $(nim --version | head -1)"
    else
        print_error "Error al instalar Nim. Visita https://nim-lang.org/install.html"
        exit 1
    fi
}

build_project() {
    print_step "Compilando módulos del proyecto..."

    export PATH="$HOME/.nimble/bin:$PATH"

    # Lista de módulos principales (en orden de dependencias)
    MODULES=(
        "agent_base.nim"
        "evolution_core.nim"
        "neuro_agent.nim"
        "swarm_agent.nim"
        "coevo_agent.nim"
        "knowledge_agent.nim"
        "ceo_agent.nim"
        "stack_agents.nim"
        "cache_strategy_agent.nim"
        "notification_agent.nim"
        "sync_agent.nim"
    )

    FAILED=0
    for module in "${MODULES[@]}"; do
        if nim c -o:/dev/null "$module" > /dev/null 2>&1; then
            print_ok "Módulo compilado: $module"
        else
            print_error "Error en: $module"
            FAILED=$((FAILED + 1))
        fi
    done

    if [ $FAILED -gt 0 ]; then
        print_error "$FAILED módulos fallaron al compilar."
        exit 1
    fi

    print_step "Compilando ejemplos ejecutables..."

    EXAMPLES=(
        "example_integrated_ceo_stack.nim"
        "example_swarm.nim"
        "example_knowledge.nim"
        "example_coevolution.nim"
        "example_foraging.nim"
        "example_pwa_integrated.nim"
    )

    mkdir -p bin
    for example in "${EXAMPLES[@]}"; do
        binary="bin/${example%.nim}"
        if nim c -o:"$binary" "$example" > /dev/null 2>&1; then
            print_ok "Ejemplo compilado: $binary"
        else
            print_warn "Advertencia: No se pudo compilar $example"
        fi
    done
}

print_usage() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Instalación completada exitosamente!${NC}"
    echo ""
    echo "  Para ejecutar los ejemplos:"
    echo ""
    echo "    ./bin/example_integrated_ceo_stack   # CEO + Stack Agents"
    echo "    ./bin/example_swarm                  # Swarm Intelligence"
    echo "    ./bin/example_knowledge              # Knowledge Agents"
    echo "    ./bin/example_coevolution            # Co-evolución"
    echo "    ./bin/example_foraging               # Foraging Behavior"
    echo "    ./bin/example_pwa_integrated         # PWA Agents"
    echo ""
    echo "  O compilar y ejecutar directamente:"
    echo ""
    echo "    nim c -r example_integrated_ceo_stack.nim"
    echo ""
    echo "  Documentación: README.md | START_HERE.md | INDEX.md"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
}

# Main
print_header

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Uso: ./install.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --skip-nim    Omitir la instalación de Nim (si ya está instalado)"
    echo "  --help        Mostrar esta ayuda"
    exit 0
fi

check_dependencies

if [[ "$1" != "--skip-nim" ]]; then
    install_nim
fi

cd "$(dirname "$0")"
build_project
print_usage

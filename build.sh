#!/usr/bin/env bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Compilación
## ═══════════════════════════════════════════════════════════════════════════
## Compila todos los módulos y ejemplos del proyecto.
## Uso: ./build.sh [--release] [--clean] [target]
## ═══════════════════════════════════════════════════════════════════════════

set -e

export PATH="$HOME/.nimble/bin:$PATH"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NIM_FLAGS="-d:debug --hints:off"
RELEASE=false
CLEAN=false
TARGET=""

# Parsear argumentos
for arg in "$@"; do
    case $arg in
        --release) RELEASE=true; NIM_FLAGS="-d:release --opt:speed --hints:off" ;;
        --clean) CLEAN=true ;;
        *) TARGET="$arg" ;;
    esac
done

echo -e "${CYAN}CEO-Agents Build System${NC}"
echo "Modo: $([ "$RELEASE" = true ] && echo 'RELEASE' || echo 'DEBUG')"
echo ""

# Limpiar si se solicita
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Limpiando artefactos de compilación...${NC}"
    rm -rf bin/ nimcache/
    find . -name "*.o" -delete 2>/dev/null || true
    echo -e "${GREEN}✓ Limpieza completada${NC}"
    echo ""
fi

mkdir -p bin

compile() {
    local src="$1"
    local out="bin/${src%.nim}"
    echo -n "  Compilando $src... "
    if nim c $NIM_FLAGS -o:"$out" "$src" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        nim c $NIM_FLAGS -o:"$out" "$src" 2>&1 | grep "Error:" | head -3
        return 1
    fi
}

if [ -n "$TARGET" ]; then
    # Compilar target específico
    compile "$TARGET"
else
    # Compilar todos los ejemplos
    echo "Compilando ejemplos:"
    FAILED=0
    for f in example_*.nim; do
        compile "$f" || FAILED=$((FAILED + 1))
    done

    echo ""
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Todos los ejemplos compilados exitosamente${NC}"
        echo ""
        echo "Ejecutables disponibles en ./bin/:"
        ls bin/ | sed 's/^/  /'
    else
        echo -e "${RED}✗ $FAILED ejemplo(s) fallaron${NC}"
        exit 1
    fi
fi

#!/bin/bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Compilación Robustecido
## ═══════════════════════════════════════════════════════════════════════════
## Compila todos los módulos core y ejemplos usando Nim 2.x y MM:ORC.
## ═══════════════════════════════════════════════════════════════════════════

set -e

export PATH="$HOME/.nimble/bin:$PATH"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}--- Iniciando Build de CEO-Agents (Nim 2.x | MM:ORC) ---${NC}"

mkdir -p bin

# 1. Compilación de módulos core (ORC para eficiencia)
echo -e "${YELLOW}Compilando módulos core...${NC}"
nim c -d:release --mm:orc src/agent_base.nim
nim c -d:release --mm:orc src/evolution_core.nim
echo -e "${GREEN}✓ Módulos core listos${NC}"

# 2. Compilación de Ejemplos
echo -e "${YELLOW}Compilando ejemplos...${NC}"
for f in examples/example_*.nim; do
    name=$(basename "$f" .nim)
    echo -n "  Compilando $name... "
    if nim c -d:debug --mm:orc --threads:on --path:src -o:"bin/$name" "$f" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Error en $f${NC}"
        # Re-compilar para mostrar error
        nim c -d:debug --mm:orc --threads:on --path:src "$f" || true
    fi
done

echo -e "${CYAN}--- Proceso completado exitosamente ---${NC}"

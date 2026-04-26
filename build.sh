#!/usr/bin/env bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Compilación v2.0
## ═══════════════════════════════════════════════════════════════════════════
## Estructura del proyecto:
##   src/       -> Módulos del núcleo
##   examples/  -> Ejemplos ejecutables
##   tests/     -> Tests unitarios
##   bin/       -> Binarios compilados (generado)
##
## Uso: ./build.sh [--release] [--clean] [--sqlite] [core|examples|api|tests|all]
## ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail
export PATH="$HOME/.nimble/bin:$PATH"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NIM_FLAGS=("-d:debug" "--hints:off" "--warnings:off")
TARGET="all"
CLEAN=false
SQLITE_DEFINE=()

for arg in "$@"; do
  case "$arg" in
    --release) NIM_FLAGS=("-d:release" "--opt:speed" "--hints:off" "--warnings:off") ;;
    --clean)   CLEAN=true ;;
    --sqlite)  SQLITE_DEFINE=("-d:ceoEnableSqliteTools") ;;
    core|examples|api|tests|all) TARGET="$arg" ;;
    *)
      echo -e "${RED}Argumento desconocido: $arg${NC}"
      echo "Uso: ./build.sh [--release] [--clean] [--sqlite] [core|examples|api|tests|all]"
      exit 1 ;;
  esac
done

# Activar SQLite también via variable de entorno
if [[ "${CEO_ENABLE_SQLITE_TOOLS:-0}" == "1" ]]; then
  SQLITE_DEFINE=("-d:ceoEnableSqliteTools")
fi

# ============================================================================
# Módulos del núcleo (src/) - solo validación de sintaxis
# ============================================================================
CORE_MODULES=(
  "src/agent_base.nim"
  "src/llm_integration.nim"
  "src/tool_registry.nim"
  "src/evolution_core.nim"
  "src/neuro_agent.nim"
  "src/swarm_agent.nim"
  "src/coevo_agent.nim"
  "src/knowledge_agent.nim"
  "src/agent_execution_engine.nim"
  "src/ceo_agent.nim"
  "src/cache_strategy_agent.nim"
  "src/notification_agent.nim"
  "src/sync_agent.nim"
)

# ============================================================================
# Ejemplos ejecutables (examples/)
# ============================================================================
EXAMPLES=(
  "examples/example_ceo_functional.nim"
  "examples/example_integrated_ceo_stack.nim"
  "examples/example_swarm.nim"
  "examples/example_knowledge.nim"
  "examples/example_coevolution.nim"
  "examples/example_foraging.nim"
  "examples/example_pwa_integrated.nim"
)

# ============================================================================
# API REST
# ============================================================================
API_TARGETS=(
  "src/api_wrapper.nim"
)

# ============================================================================
# Tests
# ============================================================================
TEST_TARGETS=(
  "tests/test_agent_base.nim"
  "tests/test_evolution_core.nim"
  "tests/test_tool_registry.nim"
  "tests/test_ceo_agent.nim"
  "tests/test_api_endpoints.nim"
)

print_header() {
  echo -e "${CYAN}"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "  CEO-Agents Build System v2.0"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo -e "${NC}"
  echo "  Target: ${TARGET}"
  local mode="DEBUG"
  for flag in "${NIM_FLAGS[@]}"; do
    [[ "$flag" == "-d:release" ]] && mode="RELEASE" && break
  done
  echo "  Modo:   $mode"
  [[ ${#SQLITE_DEFINE[@]} -gt 0 ]] && echo "  SQLite: HABILITADO" || echo "  SQLite: deshabilitado (usa --sqlite para activar)"
  echo ""
}

ensure_nim() {
  if ! command -v nim >/dev/null 2>&1; then
    echo -e "${RED}✗ Nim no está disponible en PATH.${NC}"
    echo "  Ejecuta ./install.sh o añade ~/.nimble/bin al PATH."
    exit 1
  fi
  echo -e "${GREEN}✓ Nim: $(nim --version | head -1)${NC}"
}

clean_build() {
  echo -e "${YELLOW}Limpiando artefactos de compilación...${NC}"
  rm -rf bin nimcache
  find . -name "*.o" -delete 2>/dev/null || true
  echo -e "${GREEN}✓ Limpieza completada${NC}"
  echo ""
}

compile_check() {
  local src="$1"
  echo -n "  Verificando $src... "
  if nim c "${NIM_FLAGS[@]}" "${SQLITE_DEFINE[@]}" -o:/dev/null "$src" >/tmp/ceo-build.log 2>&1; then
    echo -e "${GREEN}✓${NC}"
    return 0
  fi
  echo -e "${RED}✗${NC}"
  grep -E "Error:|Warning:" /tmp/ceo-build.log | head -8 || cat /tmp/ceo-build.log | head -20
  return 1
}

compile_binary() {
  local src="$1"
  local name; name="$(basename "${src%.nim}")"
  local out="bin/${name}"
  echo -n "  Compilando $src -> $out... "
  local extra_flags=()
  [[ "$src" == *"api_wrapper"* ]] && extra_flags=("--threads:off")
  if nim c "${NIM_FLAGS[@]}" "${extra_flags[@]}" "${SQLITE_DEFINE[@]}" -o:"$out" "$src" >/tmp/ceo-build.log 2>&1; then
    echo -e "${GREEN}✓${NC}"
    return 0
  fi
  echo -e "${RED}✗${NC}"
  grep -E "Error:|Warning:" /tmp/ceo-build.log | head -8 || cat /tmp/ceo-build.log | head -20
  return 1
}

run_core() {
  echo -e "${CYAN}Validando módulos del núcleo (src/):${NC}"
  local failed=0
  for module in "${CORE_MODULES[@]}"; do
    compile_check "$module" || failed=$((failed + 1))
  done
  return $failed
}

run_examples() {
  echo -e "${CYAN}Compilando ejemplos (examples/):${NC}"
  mkdir -p bin
  local failed=0
  for example in "${EXAMPLES[@]}"; do
    compile_binary "$example" || failed=$((failed + 1))
  done
  return $failed
}

run_api() {
  echo -e "${CYAN}Compilando API REST (src/api_wrapper.nim):${NC}"
  mkdir -p bin
  compile_binary "src/api_wrapper.nim"
}

run_tests() {
  echo -e "${CYAN}Ejecutando tests (tests/):${NC}"
  local failed=0
  for test_file in "${TEST_TARGETS[@]}"; do
    if [[ -f "$test_file" ]]; then
      echo -n "  Ejecutando $test_file... "
      if nim c -r "${NIM_FLAGS[@]}" "${SQLITE_DEFINE[@]}" "$test_file" >/tmp/ceo-test.log 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${RED}✗${NC}"
        tail -10 /tmp/ceo-test.log
        failed=$((failed + 1))
      fi
    else
      echo -e "  ${YELLOW}⚠ $test_file no encontrado (skipping)${NC}"
    fi
  done
  return $failed
}

main() {
  ensure_nim
  print_header
  [[ "$CLEAN" == true ]] && clean_build

  local failed=0
  case "$TARGET" in
    core)     run_core     || failed=$? ;;
    examples) run_examples || failed=$? ;;
    api)      run_api      || failed=$? ;;
    tests)    run_tests    || failed=$? ;;
    all)
      run_core     || failed=$((failed + $?))
      echo ""
      run_examples || failed=$((failed + $?))
      echo ""
      run_api      || failed=$((failed + $?))
      ;;
  esac

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✅ Build completado sin errores${NC}"
  else
    echo -e "${RED}✗ Fallaron ${failed} objetivo(s) de compilación${NC}"
    exit 1
  fi
}

main

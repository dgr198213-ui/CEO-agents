#!/usr/bin/env bash
## ═══════════════════════════════════════════════════════════════════════════
## CEO-Agents - Script de Compilación
## ═══════════════════════════════════════════════════════════════════════════
## Targets soportados:
##   core      -> valida módulos del core
##   examples  -> compila ejemplos ejecutables
##   api       -> compila la API HTTP
##   all       -> ejecuta core + examples + api
## Uso: ./build.sh [--release] [--clean] [core|examples|api|all]
## ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

export PATH="$HOME/.nimble/bin:$PATH"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NIM_FLAGS=("-d:debug" "--hints:off")
TARGET="all"
CLEAN=false
SQLITE_DEFINE=()

for arg in "$@"; do
  case "$arg" in
    --release)
      NIM_FLAGS=("-d:release" "--opt:speed" "--hints:off")
      ;;
    --clean)
      CLEAN=true
      ;;
    core|examples|api|all)
      TARGET="$arg"
      ;;
    *)
      echo -e "${RED}Argumento desconocido: $arg${NC}"
      exit 1
      ;;
  esac
done

if [[ "${CEO_ENABLE_SQLITE_TOOLS:-0}" == "1" ]]; then
  SQLITE_DEFINE=("-d:ceoEnableSqliteTools")
fi

CORE_MODULES=(
  "agent_base.nim"
  "evolution_core.nim"
  "neuro_agent.nim"
  "swarm_agent.nim"
  "coevo_agent.nim"
  "knowledge_agent.nim"
  "llm_integration.nim"
  "tool_registry.nim"
  "agent_execution_engine.nim"
  "ceo_agent.nim"
  "example_ceo_functional.nim"
)

EXAMPLES=(
  "example_integrated_ceo_stack.nim"
  "example_swarm.nim"
  "example_knowledge.nim"
  "example_coevolution.nim"
  "example_foraging.nim"
  "example_pwa_integrated.nim"
  "example_ceo_functional.nim"
)

API_TARGETS=(
  "api_wrapper.nim"
)

print_header() {
  echo -e "${CYAN}CEO-Agents Build System${NC}"
  echo "Target: ${TARGET}"

  local mode="DEBUG"
  for flag in "${NIM_FLAGS[@]}"; do
    if [[ "$flag" == "-d:release" ]]; then
      mode="RELEASE"
      break
    fi
  done
  echo "Modo: $mode"

  if [[ ${#SQLITE_DEFINE[@]} -gt 0 ]]; then
    echo "SQLite tools: habilitadas"
  else
    echo "SQLite tools: deshabilitadas (build base estable)"
  fi
  echo ""
}

ensure_nim() {
  if ! command -v nim >/dev/null 2>&1; then
    echo -e "${RED}Nim no está disponible en PATH.${NC}"
    echo "Ejecuta ./install.sh o añade ~/.nimble/bin al PATH."
    exit 1
  fi
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
  grep -E "Error:|Hint:" /tmp/ceo-build.log | head -5 || cat /tmp/ceo-build.log | head -20
  return 1
}

compile_binary() {
  local src="$1"
  local out="bin/${src%.nim}"
  echo -n "  Compilando $src... "
  local extra_flags=()
  if [[ "$src" == "api_wrapper.nim" ]]; then
    extra_flags=("--threads:off")
  fi
  if nim c "${NIM_FLAGS[@]}" "${extra_flags[@]}" "${SQLITE_DEFINE[@]}" -o:"$out" "$src" >/tmp/ceo-build.log 2>&1; then
    echo -e "${GREEN}✓${NC}"
    return 0
  fi

  echo -e "${RED}✗${NC}"
  grep -E "Error:|Hint:" /tmp/ceo-build.log | head -5 || cat /tmp/ceo-build.log | head -20
  return 1
}

run_core() {
  echo "Validando core:"
  local failed=0
  for module in "${CORE_MODULES[@]}"; do
    compile_check "$module" || failed=$((failed + 1))
  done
  return $failed
}

run_examples() {
  echo "Compilando ejemplos:"
  mkdir -p bin
  local failed=0
  for example in "${EXAMPLES[@]}"; do
    compile_binary "$example" || failed=$((failed + 1))
  done
  return $failed
}

run_api() {
  echo "Compilando API:"
  mkdir -p bin
  local failed=0
  for target in "${API_TARGETS[@]}"; do
    compile_binary "$target" || failed=$((failed + 1))
  done
  return $failed
}

main() {
  ensure_nim
  print_header

  if [[ "$CLEAN" == true ]]; then
    clean_build
  fi

  local failed=0
  case "$TARGET" in
    core)
      run_core || failed=$?
      ;;
    examples)
      run_examples || failed=$?
      ;;
    api)
      run_api || failed=$?
      ;;
    all)
      run_core || failed=$((failed + $?))
      echo ""
      run_examples || failed=$((failed + $?))
      echo ""
      run_api || failed=$((failed + $?))
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

#!/usr/bin/env bash
## ============================================================================
## CEO-Agents - Script de Tests
## ============================================================================
## Ejecuta todos los tests del proyecto (Nim + Frontend)
## Uso: ./scripts/run_tests.sh [--nim-only] [--frontend-only] [--coverage]
## ============================================================================

set -euo pipefail
export PATH="$HOME/.nimble/bin:$PATH"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

NIM_ONLY=false
FRONTEND_ONLY=false
COVERAGE=false

for arg in "$@"; do
  case "$arg" in
    --nim-only)      NIM_ONLY=true ;;
    --frontend-only) FRONTEND_ONLY=true ;;
    --coverage)      COVERAGE=true ;;
  esac
done

PASS=0
FAIL=0
SKIP=0

run_nim_tests() {
  echo -e "${CYAN}═══ Tests Nim ═══${NC}"

  if ! command -v nim >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Nim no disponible. Instala con: ./scripts/install_nim.sh${NC}"
    SKIP=$((SKIP + 1))
    return
  fi

  for test_file in tests/test_*.nim; do
    if [[ -f "$test_file" ]]; then
      echo -n "  $test_file... "
      if nim c -r -d:debug --hints:off --warnings:off "$test_file" >/tmp/test_output.log 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASS=$((PASS + 1))
      else
        echo -e "${RED}✗ FAIL${NC}"
        tail -10 /tmp/test_output.log
        FAIL=$((FAIL + 1))
      fi
    fi
  done
}

run_frontend_tests() {
  echo -e "${CYAN}═══ Tests Frontend ═══${NC}"

  if [[ ! -d "frontend" ]]; then
    echo -e "${YELLOW}⚠ Directorio frontend no encontrado${NC}"
    SKIP=$((SKIP + 1))
    return
  fi

  cd frontend

  if ! command -v pnpm >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ pnpm no disponible${NC}"
    SKIP=$((SKIP + 1))
    cd ..
    return
  fi

  echo -n "  TypeScript check... "
  if pnpm exec tsc --noEmit >/tmp/ts_output.log 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    cat /tmp/ts_output.log | head -20
    FAIL=$((FAIL + 1))
  fi

  echo -n "  ESLint... "
  if pnpm run lint >/tmp/lint_output.log 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${YELLOW}⚠ WARNINGS${NC}"
    cat /tmp/lint_output.log | head -10
  fi

  echo -n "  Build... "
  if NEXT_PUBLIC_API_URL=http://localhost:8080 pnpm run build >/tmp/build_output.log 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    tail -20 /tmp/build_output.log
    FAIL=$((FAIL + 1))
  fi

  cd ..
}

echo ""
echo -e "${CYAN}CEO-Agents Test Suite${NC}"
echo "═══════════════════════════════════════"
echo ""

[[ "$FRONTEND_ONLY" == false ]] && run_nim_tests
echo ""
[[ "$NIM_ONLY" == false ]] && run_frontend_tests

echo ""
echo "═══════════════════════════════════════"
echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  ${YELLOW}SKIP: $SKIP${NC}"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}✗ Tests fallidos: $FAIL${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Todos los tests pasaron${NC}"
fi

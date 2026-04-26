#!/usr/bin/env bash
## ============================================================================
## CEO-Agents - Instalador de Nim
## ============================================================================
## Instala Nim via choosenim para desarrollo local y CI
## Uso: ./scripts/install_nim.sh [version]
## ============================================================================

set -euo pipefail

NIM_VERSION="${1:-stable}"
CHOOSENIM_URL="https://nim-lang.org/choosenim/init.sh"

echo "Instalando Nim $NIM_VERSION via choosenim..."

# Instalar choosenim
curl -sSf "$CHOOSENIM_URL" | sh -s -- -y

# Añadir al PATH
export PATH="$HOME/.nimble/bin:$PATH"

# Seleccionar versión si no es stable
if [[ "$NIM_VERSION" != "stable" ]]; then
  choosenim "$NIM_VERSION"
fi

echo "Nim instalado:"
nim --version | head -1
nimble --version | head -1

echo ""
echo "Añade esto a tu ~/.bashrc o ~/.zshrc:"
echo '  export PATH="$HOME/.nimble/bin:$PATH"'

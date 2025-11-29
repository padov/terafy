#!/bin/bash
# Script para compilar localmente e enviar binário para a VM
# Uso: ./build-and-deploy.sh [VM_NAME]
# 
# NOTA: Este script agora usa prepare-deploy.sh internamente
# Mantido para compatibilidade com scripts existentes

set -e

VM_NAME=${1:-terafy-freetier-vm}
NEW_DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 Usando script completo de preparação..."
echo ""

# Usar o script completo de preparação
"$NEW_DEPLOY_DIR/prepare-deploy.sh" "$VM_NAME"


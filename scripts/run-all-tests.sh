#!/bin/bash
# Script unificado para executar todos os testes (backend + frontend)
# Uso: ./scripts/run-all-tests.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="$PROJECT_ROOT/deploy"

echo "🚀 Executando todos os testes..."
echo "════════════════════════════════════════"
echo ""

# Executar testes do backend
echo "📦 BACKEND"
echo "────────────────────────────────────────"
if ! "$DEPLOY_DIR/run-backend-tests.sh"; then
    echo ""
    echo "❌ Testes do backend falharam!"
    exit 1
fi

echo ""

# Executar testes do frontend
echo "📱 FRONTEND"
echo "────────────────────────────────────────"
if ! "$DEPLOY_DIR/run-frontend-tests.sh"; then
    echo ""
    echo "❌ Testes do frontend falharam!"
    exit 1
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ Todos os testes passaram com sucesso!"
echo ""


#!/bin/bash
# Script para executar testes do frontend
# Uso: ./run-frontend-tests.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"
COVERAGE_DIR="$APP_DIR/coverage"
MIN_COVERAGE=80

echo "🧪 Executando testes do frontend..."
echo ""

cd "$APP_DIR"

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Erro: Flutter não está instalado ou não está no PATH"
    exit 1
fi

# Instalar dependências
echo "📦 Instalando dependências..."
flutter pub get > /dev/null 2>&1

# Executar testes unitários
echo "▶️  Executando testes unitários..."
if ! flutter test; then
    echo ""
    echo "❌ Erro: Testes do frontend falharam!"
    exit 1
fi

# Executar testes com cobertura
echo ""
echo "📊 Gerando relatório de cobertura..."
flutter test --coverage > /dev/null 2>&1

# Validar cobertura mínima
if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    echo "📈 Validando cobertura mínima ($MIN_COVERAGE%)..."
    TOTAL_LINES=$(grep -c "^DA:" "$COVERAGE_DIR/lcov.info" 2>/dev/null || echo "0")
    COVERED_LINES=$(grep "^DA:" "$COVERAGE_DIR/lcov.info" | grep -v ",0$" | wc -l | tr -d ' ' || echo "0")
    
    if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE_PERCENT=$((COVERED_LINES * 100 / TOTAL_LINES))
        echo "📊 Cobertura atual: $COVERAGE_PERCENT% ($COVERED_LINES/$TOTAL_LINES linhas)"
        
        if [ "$COVERAGE_PERCENT" -lt "$MIN_COVERAGE" ]; then
            echo ""
            echo "❌ Erro: Cobertura ($COVERAGE_PERCENT%) abaixo do mínimo exigido ($MIN_COVERAGE%)!"
            echo "💡 Adicione mais testes para aumentar a cobertura."
            exit 1
        else
            echo "✅ Cobertura acima do mínimo ($MIN_COVERAGE%)"
        fi
    fi
fi

echo ""
echo "✅ Testes do frontend passaram com sucesso!"
echo "📁 Relatório de cobertura: $COVERAGE_DIR/lcov.info"
echo ""


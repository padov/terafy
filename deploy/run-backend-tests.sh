#!/bin/bash
# Script para executar testes do backend
# Uso: ./run-backend-tests.sh [--fail-fast|-f]
#
# Opções:
#   --fail-fast, -f    Para no primeiro teste que falhar (útil para debug)

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
COVERAGE_DIR="$SERVER_DIR/coverage"
MIN_COVERAGE=80

# Verifica se foi passado o parâmetro --fail-fast ou -f
FAIL_FAST=false
if [[ "$1" == "--fail-fast" || "$1" == "-f" ]]; then
    FAIL_FAST=true
fi

echo "🧪 Executando testes do backend..."
if [ "$FAIL_FAST" = true ]; then
    echo "⚡ Modo fail-fast ativado (parará no primeiro erro)"
fi
echo ""

cd "$SERVER_DIR"

# Instalar dependências
echo "📦 Instalando dependências..."
dart pub get > /dev/null 2>&1

# Executar testes
echo "▶️  Executando testes..."
TEST_ARGS=""
if [ "$FAIL_FAST" = true ]; then
    TEST_ARGS="--fail-fast"
fi

# Testes de integração compartilham o mesmo banco, então precisam rodar sequencialmente
# para evitar conflitos de concorrência (deadlocks, timeouts)
# O mutex em IntegrationTestDB.cleanDatabase() também ajuda, mas --concurrency=1 é mais seguro
if ! dart test --concurrency=1 $TEST_ARGS; then
    echo ""
    echo "❌ Erro: Testes do backend falharam!"
    if [ "$FAIL_FAST" = true ]; then
        echo "💡 Parou no primeiro erro (modo fail-fast ativado)"
    fi
    exit 1
fi

# Executar testes com cobertura
echo ""
echo "📊 Gerando relatório de cobertura..."
if ! dart test --coverage="$COVERAGE_DIR" --concurrency=1 $TEST_ARGS > /dev/null 2>&1; then
    echo "⚠️  Aviso: Alguns testes falharam durante geração de cobertura"
    echo "   Continuando mesmo assim para gerar relatório parcial..."
fi

# Verificar se diretório de cobertura foi criado
if [ ! -d "$COVERAGE_DIR" ]; then
    echo "❌ Erro: Diretório de cobertura não foi criado: $COVERAGE_DIR"
    exit 1
fi

# Formatar cobertura para LCOV
echo "📝 Formatando relatório LCOV..."
if ! dart pub global activate coverage 2>&1; then
    echo "❌ Erro: Não foi possível instalar/ativar pacote coverage"
    echo "   Tente executar manualmente: dart pub global activate coverage"
    exit 1
fi

# Executa o format_coverage a partir do diretório do servidor para garantir caminhos corretos
cd "$SERVER_DIR"
if ! dart pub global run coverage:format_coverage \
    --lcov \
    --in="coverage" \
    --out="coverage/lcov.info" \
    --package="." \
    --report-on=lib \
    2>&1; then
    echo ""
    echo "❌ Erro: Não foi possível gerar relatório LCOV"
    echo "   Verifique se o diretório de cobertura contém arquivos:"
    echo "   ls -la $COVERAGE_DIR"
    exit 1
fi
cd "$PROJECT_ROOT"

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
echo "✅ Testes do backend passaram com sucesso!"
echo "📁 Relatório de cobertura: $COVERAGE_DIR/lcov.info"
echo ""


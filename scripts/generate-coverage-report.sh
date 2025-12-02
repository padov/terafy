#!/bin/bash
# Script para gerar relatórios de cobertura completos (backend + frontend)
# Uso: ./scripts/generate-coverage-report.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
APP_DIR="$PROJECT_ROOT/app"
REPORTS_DIR="$PROJECT_ROOT/coverage-reports"
MIN_COVERAGE=80

echo "📊 Gerando relatórios de cobertura completos..."
echo "════════════════════════════════════════════════"
echo ""

# Criar diretório de relatórios
mkdir -p "$REPORTS_DIR"
mkdir -p "$REPORTS_DIR/backend"
mkdir -p "$REPORTS_DIR/frontend"

# ============================================
# BACKEND: Gerar cobertura e relatório HTML
# ============================================
echo "📦 BACKEND"
echo "────────────────────────────────────────"

cd "$SERVER_DIR"

# Instalar dependências
echo "📦 Instalando dependências..."
dart pub get > /dev/null 2>&1

# Executar testes com cobertura
echo "▶️  Executando testes com cobertura..."
COVERAGE_DIR="$SERVER_DIR/coverage"
mkdir -p "$COVERAGE_DIR"

dart test --coverage="$COVERAGE_DIR" > /dev/null 2>&1

# Ativar coverage package globalmente
echo "🔧 Configurando ferramentas de cobertura..."
dart pub global activate coverage 2>/dev/null || true

# Formatar cobertura para LCOV
echo "📝 Formatando relatório LCOV..."
dart pub global run coverage:format_coverage \
    --lcov \
    --in="$COVERAGE_DIR" \
    --out="$COVERAGE_DIR/lcov.info" \
    --packages="$SERVER_DIR/.dart_tool/package_config.json" \
    --report-on=lib \
    2>/dev/null || echo "⚠️  Aviso: Não foi possível gerar relatório LCOV detalhado"

# Gerar relatório HTML (se lcov estiver disponível)
if command -v genhtml &> /dev/null; then
    echo "🌐 Gerando relatório HTML..."
    genhtml "$COVERAGE_DIR/lcov.info" \
        -o "$REPORTS_DIR/backend/html" \
        --title "Terafy Backend - Cobertura de Código" \
        --no-function-coverage \
        --no-branch-coverage \
        2>/dev/null || echo "⚠️  Aviso: Não foi possível gerar relatório HTML (instale lcov: brew install lcov)"
else
    echo "⚠️  lcov não encontrado. Para gerar relatório HTML, instale: brew install lcov"
fi

# Calcular cobertura total
if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    echo "📈 Calculando cobertura total..."
    # Copiar LCOV para relatórios
    cp "$COVERAGE_DIR/lcov.info" "$REPORTS_DIR/backend/lcov.info"
    
    # Tentar calcular porcentagem (básico)
    TOTAL_LINES=$(grep -c "^DA:" "$COVERAGE_DIR/lcov.info" 2>/dev/null || echo "0")
    COVERED_LINES=$(grep "^DA:" "$COVERAGE_DIR/lcov.info" | grep -v ",0$" | wc -l | tr -d ' ' || echo "0")
    
    if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE_PERCENT=$((COVERED_LINES * 100 / TOTAL_LINES))
        echo "📊 Cobertura: $COVERAGE_PERCENT% ($COVERED_LINES/$TOTAL_LINES linhas)"
        
        if [ "$COVERAGE_PERCENT" -lt "$MIN_COVERAGE" ]; then
            echo "⚠️  Aviso: Cobertura ($COVERAGE_PERCENT%) abaixo do mínimo ($MIN_COVERAGE%)"
        else
            echo "✅ Cobertura acima do mínimo ($MIN_COVERAGE%)"
        fi
    fi
fi

echo ""

# ============================================
# FRONTEND: Gerar cobertura e relatório HTML
# ============================================
echo "📱 FRONTEND"
echo "────────────────────────────────────────"

cd "$APP_DIR"

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter não encontrado, pulando cobertura do frontend"
else
    # Instalar dependências
    echo "📦 Instalando dependências..."
    flutter pub get > /dev/null 2>&1
    
    # Executar testes com cobertura
    echo "▶️  Executando testes com cobertura..."
    COVERAGE_DIR="$APP_DIR/coverage"
    mkdir -p "$COVERAGE_DIR"
    
    flutter test --coverage > /dev/null 2>&1
    
    # Gerar relatório HTML (se lcov estiver disponível)
    if [ -f "$COVERAGE_DIR/lcov.info" ]; then
        # Copiar LCOV para relatórios
        cp "$COVERAGE_DIR/lcov.info" "$REPORTS_DIR/frontend/lcov.info"
        
        if command -v genhtml &> /dev/null; then
            echo "🌐 Gerando relatório HTML..."
            genhtml "$COVERAGE_DIR/lcov.info" \
                -o "$REPORTS_DIR/frontend/html" \
                --title "Terafy Frontend - Cobertura de Código" \
                --no-function-coverage \
                --no-branch-coverage \
                2>/dev/null || echo "⚠️  Aviso: Não foi possível gerar relatório HTML"
        else
            echo "⚠️  lcov não encontrado. Para gerar relatório HTML, instale: brew install lcov"
        fi
        
        # Calcular cobertura total
        echo "📈 Calculando cobertura total..."
        TOTAL_LINES=$(grep -c "^DA:" "$COVERAGE_DIR/lcov.info" 2>/dev/null || echo "0")
        COVERED_LINES=$(grep "^DA:" "$COVERAGE_DIR/lcov.info" | grep -v ",0$" | wc -l | tr -d ' ' || echo "0")
        
        if [ "$TOTAL_LINES" -gt 0 ]; then
            COVERAGE_PERCENT=$((COVERED_LINES * 100 / TOTAL_LINES))
            echo "📊 Cobertura: $COVERAGE_PERCENT% ($COVERED_LINES/$TOTAL_LINES linhas)"
            
            if [ "$COVERAGE_PERCENT" -lt "$MIN_COVERAGE" ]; then
                echo "⚠️  Aviso: Cobertura ($COVERAGE_PERCENT%) abaixo do mínimo ($MIN_COVERAGE%)"
            else
                echo "✅ Cobertura acima do mínimo ($MIN_COVERAGE%)"
            fi
        fi
    fi
fi

echo ""

# ============================================
# RESUMO
# ============================================
echo "════════════════════════════════════════════════"
echo "✅ Relatórios de cobertura gerados!"
echo ""
echo "📁 Localização dos relatórios:"
echo "   Backend LCOV:  $REPORTS_DIR/backend/lcov.info"
if [ -d "$REPORTS_DIR/backend/html" ]; then
    echo "   Backend HTML:  $REPORTS_DIR/backend/html/index.html"
fi
echo "   Frontend LCOV: $REPORTS_DIR/frontend/lcov.info"
if [ -d "$REPORTS_DIR/frontend/html" ]; then
    echo "   Frontend HTML: $REPORTS_DIR/frontend/html/index.html"
fi
echo ""
echo "💡 Para visualizar relatórios HTML:"
if [ -d "$REPORTS_DIR/backend/html" ]; then
    echo "   open $REPORTS_DIR/backend/html/index.html"
fi
if [ -d "$REPORTS_DIR/frontend/html" ]; then
    echo "   open $REPORTS_DIR/frontend/html/index.html"
fi
echo ""


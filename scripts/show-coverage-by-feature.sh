#!/bin/bash
# Script para mostrar cobertura por feature/diretório
# Uso: ./scripts/show-coverage-by-feature.sh [backend|frontend|both]

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
APP_DIR="$PROJECT_ROOT/app"

# Função para mostrar cobertura de um tipo específico
show_coverage() {
    local TYPE=$1
    local COVERAGE_FILE=""
    local SOURCE_DIR=""
    local TITLE=""
    
    if [ "$TYPE" == "backend" ]; then
        COVERAGE_FILE="$SERVER_DIR/coverage/lcov.info"
        SOURCE_DIR="$SERVER_DIR/lib"
        TITLE="Backend"
    elif [ "$TYPE" == "frontend" ]; then
        COVERAGE_FILE="$APP_DIR/coverage/lcov.info"
        SOURCE_DIR="$APP_DIR/lib"
        TITLE="Frontend"
    fi
    
    if [ ! -f "$COVERAGE_FILE" ]; then
        echo "❌ Erro: Arquivo de cobertura não encontrado: $COVERAGE_FILE"
        echo "   Execute primeiro: ./deploy/run-${TYPE}-tests.sh"
        return 1
    fi
    
    echo "📊 Cobertura por Feature - $TITLE"
    echo "════════════════════════════════════════════════"
    echo ""

# Processa arquivo LCOV e agrupa por feature
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Processa arquivo LCOV
CURRENT_FILE=""
CURRENT_FEATURE=""

while IFS= read -r line || [ -n "$line" ]; do
    # Linha SF: indica início de um arquivo fonte
    if [[ $line =~ ^SF:(.+) ]]; then
        CURRENT_FILE="${BASH_REMATCH[1]}"
        CURRENT_FEATURE=""
        
        # Extrai o caminho relativo ao diretório de código fonte
        if [[ $CURRENT_FILE == *"$SOURCE_DIR"* ]]; then
            # Remove o caminho do diretório fonte
            REL_PATH="${CURRENT_FILE#*$SOURCE_DIR/}"
            
            # Extrai a feature (primeiro diretório após features/)
            if [[ $REL_PATH =~ ^features/([^/]+) ]]; then
                CURRENT_FEATURE="${BASH_REMATCH[1]}"
            elif [[ $REL_PATH =~ ^core/([^/]+) ]]; then
                CURRENT_FEATURE="core_${BASH_REMATCH[1]}"
            else
                CURRENT_FEATURE="outros"
            fi
            
            # Sanitiza nome do arquivo (substitui / por _)
            FEATURE_KEY=$(echo "$CURRENT_FEATURE" | tr '/' '_')
            
            # Cria arquivo temporário para esta feature se não existir
            if [ ! -f "$TEMP_DIR/$FEATURE_KEY" ]; then
                echo "0 0" > "$TEMP_DIR/$FEATURE_KEY"  # total covered
                echo "0" > "$TEMP_DIR/${FEATURE_KEY}_files"  # files count
                echo "$CURRENT_FEATURE" > "$TEMP_DIR/${FEATURE_KEY}_name"  # nome original
            fi
            
            # Incrementa contador de arquivos
            FILES_COUNT=$(cat "$TEMP_DIR/${FEATURE_KEY}_files" 2>/dev/null || echo "0")
            echo $((FILES_COUNT + 1)) > "$TEMP_DIR/${FEATURE_KEY}_files"
        fi
    fi
    
    # Linha DA: indica uma linha de código com cobertura
    if [[ $line =~ ^DA:([0-9]+),([0-9]+) ]]; then
        HIT_COUNT="${BASH_REMATCH[2]}"
        
        if [ -n "$CURRENT_FEATURE" ]; then
            FEATURE_KEY=$(echo "$CURRENT_FEATURE" | tr '/' '_')
            if [ -f "$TEMP_DIR/$FEATURE_KEY" ]; then
                # Lê total e covered
                read TOTAL COVERED < "$TEMP_DIR/$FEATURE_KEY"
            
            TOTAL=$((TOTAL + 1))
            if [ "$HIT_COUNT" -gt 0 ]; then
                COVERED=$((COVERED + 1))
            fi
            
                echo "$TOTAL $COVERED" > "$TEMP_DIR/$FEATURE_KEY"
            fi
        fi
    fi
done < "$COVERAGE_FILE"

# Exibe resultados
echo "Feature                          | Arquivos | Linhas    | Cobertura"
echo "─────────────────────────────────┼──────────┼───────────┼──────────"

TOTAL_FILES=0
TOTAL_LINES=0
TOTAL_COVERED=0

# Processa e exibe cada feature (ordenado)
FEATURES_LIST=""
for FEATURE_FILE in "$TEMP_DIR"/*_files; do
    if [ -f "$FEATURE_FILE" ]; then
        FEATURE_KEY=$(basename "$FEATURE_FILE" | sed 's/_files$//')
        FEATURE=$(cat "$TEMP_DIR/${FEATURE_KEY}_name" 2>/dev/null || echo "$FEATURE_KEY")
        FILES=$(cat "$FEATURE_FILE")
        read TOTAL COVERED < "$TEMP_DIR/$FEATURE_KEY" 2>/dev/null || echo "0 0"
        
        if [ "$TOTAL" -gt 0 ]; then
            FEATURES_LIST="${FEATURES_LIST}${FEATURE}|${FILES}|${TOTAL}|${COVERED}
"
            TOTAL_FILES=$((TOTAL_FILES + FILES))
            TOTAL_LINES=$((TOTAL_LINES + TOTAL))
            TOTAL_COVERED=$((TOTAL_COVERED + COVERED))
        fi
    fi
done

# Ordena e exibe
echo "$FEATURES_LIST" | sort | while IFS='|' read -r FEATURE FILES TOTAL COVERED; do
    if [ -n "$FEATURE" ]; then
        PERCENT=$((COVERED * 100 / TOTAL))
        
        # Cor baseado na cobertura
        if [ "$PERCENT" -ge 80 ]; then
            STATUS="✅"
        elif [ "$PERCENT" -ge 50 ]; then
            STATUS="⚠️ "
        else
            STATUS="❌"
        fi
        
        printf "%-32s | %8s | %5s/%5s | %3s%% %s\n" \
            "$FEATURE" \
            "$FILES" \
            "$COVERED" \
            "$TOTAL" \
            "$PERCENT" \
            "$STATUS"
    fi
done

echo "─────────────────────────────────┼──────────┼───────────┼──────────"
if [ "$TOTAL_LINES" -gt 0 ]; then
    TOTAL_PERCENT=$((TOTAL_COVERED * 100 / TOTAL_LINES))
    if [ "$TOTAL_PERCENT" -ge 80 ]; then
        STATUS="✅"
    elif [ "$TOTAL_PERCENT" -ge 50 ]; then
        STATUS="⚠️ "
    else
        STATUS="❌"
    fi
    printf "%-32s | %8s | %5s/%5s | %3s%% %s\n" \
        "TOTAL" \
        "$TOTAL_FILES" \
        "$TOTAL_COVERED" \
        "$TOTAL_LINES" \
        "$TOTAL_PERCENT" \
        "$STATUS"
fi

echo ""
echo "💡 Para visualizar HTML completo (requer lcov):"
if [ "$TYPE" == "backend" ]; then
    echo "   brew install lcov"
    echo "   cd $SERVER_DIR && genhtml coverage/lcov.info -o coverage/html"
    echo "   open coverage/html/index.html"
elif [ "$TYPE" == "frontend" ]; then
    echo "   brew install lcov"
    echo "   cd $APP_DIR && genhtml coverage/lcov.info -o coverage/html"
    echo "   open coverage/html/index.html"
fi
}

# Determina qual cobertura mostrar
MODE="${1:-backend}"

if [ "$MODE" == "both" ]; then
    echo "╔════════════════════════════════════════════════╗"
    echo "║     📊 RELATÓRIO DE COBERTURA COMPLETO        ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
    
    # Mostra backend
    show_coverage "backend"
    BACKEND_STATUS=$?
    
    echo ""
    echo ""
    
    # Mostra frontend
    show_coverage "frontend"
    FRONTEND_STATUS=$?
    
    echo ""
    echo "════════════════════════════════════════════════"
    echo "📋 RESUMO"
    echo "════════════════════════════════════════════════"
    
    if [ $BACKEND_STATUS -eq 0 ]; then
        echo "✅ Backend:  Cobertura disponível"
    else
        echo "❌ Backend:  Cobertura não encontrada"
    fi
    
    if [ $FRONTEND_STATUS -eq 0 ]; then
        echo "✅ Frontend: Cobertura disponível"
    else
        echo "❌ Frontend: Cobertura não encontrada"
    fi
    
    echo ""
    echo "💡 Dica: Execute os testes antes de gerar cobertura:"
    echo "   ./deploy/run-backend-tests.sh"
    echo "   ./deploy/run-frontend-tests.sh"
    
elif [ "$MODE" == "backend" ] || [ "$MODE" == "frontend" ]; then
    show_coverage "$MODE"
else
    echo "❌ Erro: Modo inválido. Use 'backend', 'frontend' ou 'both'"
    echo ""
    echo "📖 Uso:"
    echo "   ./scripts/show-coverage-by-feature.sh backend   # Mostra apenas backend"
    echo "   ./scripts/show-coverage-by-feature.sh frontend  # Mostra apenas frontend"
    echo "   ./scripts/show-coverage-by-feature.sh both      # Mostra ambos"
    echo ""
    exit 1
fi

#!/bin/bash
# Script para gerenciar banco de dados de testes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/.."

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funções
start_db() {
    echo -e "${GREEN}🚀 Iniciando banco de dados de testes...${NC}"
    cd "$SERVER_DIR"
    docker compose -f docker-compose.test.yml up -d
    
    echo -e "${YELLOW}⏳ Aguardando banco ficar pronto...${NC}"
    sleep 3
    
    # Aguarda healthcheck
    for i in {1..30}; do
        if docker compose -f docker-compose.test.yml exec -T postgres-test pg_isready -U test_user -d terafy_test > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Banco de dados pronto!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo -e "${RED}❌ Timeout aguardando banco de dados${NC}"
    return 1
}

stop_db() {
    echo -e "${YELLOW}🛑 Parando banco de dados de testes...${NC}"
    cd "$SERVER_DIR"
    docker compose -f docker-compose.test.yml down
    echo -e "${GREEN}✅ Banco parado${NC}"
}

reset_db() {
    echo -e "${YELLOW}🔄 Resetando banco de dados de testes...${NC}"
    cd "$SERVER_DIR"
    docker compose -f docker-compose.test.yml down -v
    docker compose -f docker-compose.test.yml up -d
    
    echo -e "${YELLOW}⏳ Aguardando banco ficar pronto...${NC}"
    sleep 3
    
    for i in {1..30}; do
        if docker compose -f docker-compose.test.yml exec -T postgres-test pg_isready -U test_user -d terafy_test > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Banco resetado e pronto!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo -e "${RED}❌ Timeout aguardando banco de dados${NC}"
    return 1
}

status_db() {
    echo -e "${GREEN}📊 Status do banco de testes:${NC}"
    cd "$SERVER_DIR"
    docker compose -f docker-compose.test.yml ps
}

logs_db() {
    echo -e "${GREEN}📋 Logs do banco de testes:${NC}"
    cd "$SERVER_DIR"
    docker compose -f docker-compose.test.yml logs -f postgres-test
}

# Menu
case "$1" in
    start)
        start_db
        ;;
    stop)
        stop_db
        ;;
    reset)
        reset_db
        ;;
    status)
        status_db
        ;;
    logs)
        logs_db
        ;;
    *)
        echo "Uso: $0 {start|stop|reset|status|logs}"
        echo ""
        echo "Comandos:"
        echo "  start  - Inicia o banco de dados de testes"
        echo "  stop   - Para o banco de dados de testes"
        echo "  reset  - Reseta o banco (apaga todos os dados)"
        echo "  status - Mostra status do container"
        echo "  logs   - Mostra logs do banco"
        exit 1
        ;;
esac

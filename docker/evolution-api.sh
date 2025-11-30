#!/bin/bash

# Script helper para gerenciar o Evolution API de teste
# Uso: ./evolution-api.sh [comando]

set -e

COMPOSE_FILE="docker-compose.evolution-api.yml"
CONTAINER_NAME="evolution-api-test"
API_KEY="${EVOLUTION_API_KEY:-terafy-test-key-change-me}"
API_URL="http://localhost:8080"
INSTANCE_NAME="${WHATSAPP_INSTANCE_NAME:-terafy-instance}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se docker-compose está disponível
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado ou não está no PATH"
    exit 1
fi

# Usar docker compose (v2) se disponível, senão docker-compose (v1)
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Comandos disponíveis
case "${1:-help}" in
    start|up)
        print_info "Iniciando Evolution API..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d
        print_info "Aguardando serviço iniciar..."
        sleep 5
        if curl -f -s "$API_URL/health" > /dev/null 2>&1; then
            print_info "Evolution API está rodando em $API_URL"
        else
            print_warn "Evolution API pode não estar pronto ainda. Verifique os logs com: ./evolution-api.sh logs"
        fi
        ;;
    
    stop|down)
        print_info "Parando Evolution API..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down
        print_info "Evolution API parado"
        ;;
    
    restart)
        print_info "Reiniciando Evolution API..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" restart
        print_info "Evolution API reiniciado"
        ;;
    
    logs)
        print_info "Mostrando logs do Evolution API (Ctrl+C para sair)..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs -f evolution-api
        ;;
    
    status)
        print_info "Status dos containers:"
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps
        echo ""
        print_info "Verificando saúde da API..."
        if curl -f -s "$API_URL/health" > /dev/null 2>&1; then
            print_info "✓ API está respondendo"
        else
            print_error "✗ API não está respondendo"
        fi
        ;;
    
    create-instance)
        print_info "Criando instância WhatsApp: $INSTANCE_NAME"
        response=$(curl -s -X POST "$API_URL/instance/create" \
            -H "apikey: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"instanceName\": \"$INSTANCE_NAME\",
                \"token\": \"terafy-token\",
                \"qrcode\": true
            }")
        
        if echo "$response" | grep -q "instance"; then
            print_info "Instância criada com sucesso!"
            print_info "Acesse o QR Code em: $API_URL/instance/connect/$INSTANCE_NAME?apikey=$API_KEY"
        else
            print_error "Erro ao criar instância: $response"
        fi
        ;;
    
    connect)
        print_info "Obtendo QR Code para conectar WhatsApp..."
        print_info "Acesse: $API_URL/instance/connect/$INSTANCE_NAME?apikey=$API_KEY"
        echo ""
        print_warn "Ou escaneie o QR Code abaixo (se disponível):"
        curl -s "$API_URL/instance/connect/$INSTANCE_NAME?apikey=$API_KEY" | grep -o 'data:image[^"]*' || echo "QR Code não disponível via curl. Acesse a URL acima no navegador."
        ;;
    
    instances)
        print_info "Listando instâncias..."
        curl -s -X GET "$API_URL/instance/fetchInstances" \
            -H "apikey: $API_KEY" | jq '.' || curl -s -X GET "$API_URL/instance/fetchInstances" \
            -H "apikey: $API_KEY"
        ;;
    
    send-test)
        if [ -z "$2" ]; then
            print_error "Uso: ./evolution-api.sh send-test <número>"
            print_info "Exemplo: ./evolution-api.sh send-test 5511999999999"
            exit 1
        fi
        number="$2@s.whatsapp.net"
        print_info "Enviando mensagem de teste para $number..."
        response=$(curl -s -X POST "$API_URL/message/sendText/$INSTANCE_NAME" \
            -H "apikey: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"number\": \"$number\",
                \"text\": \"Teste de mensagem do Terafy - $(date)\"
            }")
        echo "$response" | jq '.' || echo "$response"
        ;;
    
    shell)
        print_info "Abrindo shell do container..."
        docker exec -it "$CONTAINER_NAME" sh
        ;;
    
    clean)
        print_warn "Isso irá remover todos os containers, volumes e dados do Evolution API!"
        read -p "Tem certeza? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            print_info "Removendo containers e volumes..."
            $DOCKER_COMPOSE -f "$COMPOSE_FILE" down -v
            print_info "Limpeza concluída"
        else
            print_info "Operação cancelada"
        fi
        ;;
    
    help|*)
        echo "Evolution API - Script Helper"
        echo ""
        echo "Uso: ./evolution-api.sh [comando]"
        echo ""
        echo "Comandos disponíveis:"
        echo "  start, up          - Inicia o Evolution API"
        echo "  stop, down         - Para o Evolution API"
        echo "  restart            - Reinicia o Evolution API"
        echo "  logs               - Mostra logs em tempo real"
        echo "  status             - Mostra status dos containers e API"
        echo "  create-instance    - Cria uma nova instância WhatsApp"
        echo "  connect            - Mostra URL do QR Code para conectar"
        echo "  instances          - Lista todas as instâncias"
        echo "  send-test <num>    - Envia mensagem de teste para um número"
        echo "  shell              - Abre shell do container"
        echo "  clean              - Remove containers e volumes (limpeza completa)"
        echo "  help               - Mostra esta ajuda"
        echo ""
        echo "Variáveis de ambiente:"
        echo "  EVOLUTION_API_KEY       - Chave da API (padrão: terafy-test-key-change-me)"
        echo "  WHATSAPP_INSTANCE_NAME   - Nome da instância (padrão: terafy-instance)"
        echo ""
        echo "Exemplos:"
        echo "  ./evolution-api.sh start"
        echo "  ./evolution-api.sh create-instance"
        echo "  ./evolution-api.sh connect"
        echo "  ./evolution-api.sh send-test 5511999999999"
        ;;
esac


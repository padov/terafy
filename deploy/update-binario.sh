#!/bin/bash
# Script para atualizar o servidor na VM usando binário pré-compilado
# Uso: Colocar na VM em ~/terafy-deploy/ e executar após receber terafy-deploy.tar.gz

set -e

DEPLOY_DIR="$HOME/terafy-deploy"
BACKUP_DIR="$HOME/terafy-deploy-backups"

echo "🔄 Atualizando servidor com binário pré-compilado..."
echo ""

# 1. Criar backup
if [ -d "$DEPLOY_DIR" ]; then
    echo "📦 Criando backup..."
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$BACKUP_NAME"
    echo "✅ Backup criado: $BACKUP_DIR/$BACKUP_NAME"
fi

# 2. Parar containers
echo ""
echo "🛑 Parando containers..."
cd "$DEPLOY_DIR" 2>/dev/null || true
docker compose down 2>/dev/null || true

# 3. Extrair novo pacote
echo ""
echo "📦 Extraindo novo pacote..."
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

if [ ! -f ~/terafy-deploy.tar.gz ]; then
    echo "❌ Erro: terafy-deploy.tar.gz não encontrado em ~/"
    echo "   Execute: gcloud compute scp terafy-deploy.tar.gz VM_NAME:~/"
    exit 1
fi

tar -xzf ~/terafy-deploy.tar.gz
echo "✅ Pacote extraído"

# 4. Verificar .env
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  Arquivo .env não encontrado. Copiando de env.example..."
    cp env.example .env
    echo "📝 Edite o .env com os valores corretos antes de continuar!"
    echo "   nano .env"
    read -p "Pressione Enter após editar o .env..."
fi

# 5. Build da imagem (só copia binário, muito rápido!)
echo ""
echo "🔨 Construindo imagem Docker..."
docker compose build server

# 6. Iniciar serviços
echo ""
echo "🚀 Iniciando serviços..."
docker compose up -d

# 7. Verificar status
echo ""
echo "📊 Status dos containers:"
docker compose ps

# 8. Testar servidor
echo ""
echo "🧪 Testando servidor..."
sleep 2
if curl -f http://localhost:8080/ping > /dev/null 2>&1; then
    echo "✅ Servidor respondendo corretamente!"
else
    echo "⚠️  Servidor pode não estar respondendo. Verifique os logs:"
    echo "   docker compose logs server"
fi

echo ""
echo "✅ Atualização concluída!"
echo ""
echo "📝 Comandos úteis:"
echo "   docker compose logs -f server    # Ver logs"
echo "   docker compose restart server    # Reiniciar servidor"
echo "   docker compose ps                # Ver status"


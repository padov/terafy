#!/bin/bash
# Script de atualização do sistema Terafy na VM
# Uso: ./update.sh

set -e

echo "🔄 Atualizando sistema Terafy..."
echo ""

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Erro: Execute este script de dentro de ~/terafy/docker"
    exit 1
fi

# Verificar se o arquivo terafy.tar.gz existe
if [ ! -f ~/terafy.tar.gz ]; then
    echo "❌ Arquivo terafy.tar.gz não encontrado em ~/"
    echo "   Faça upload do arquivo primeiro:"
    echo "   gcloud compute scp terafy.tar.gz terafy-freetier-vm:~/"
    exit 1
fi

# Backup opcional
read -p "Fazer backup do código atual? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    cd ~
    if [ -d terafy ]; then
        BACKUP_NAME="terafy_backup_$(date +%Y%m%d_%H%M%S)"
        cp -r terafy "$BACKUP_NAME"
        echo "✅ Backup criado: $BACKUP_NAME"
    else
        echo "⚠️  Pasta terafy não existe, pulando backup"
    fi
fi

# Parar containers antes de atualizar
echo ""
echo "🛑 Parando containers..."
cd ~/terafy/docker 2>/dev/null || true
if [ -f docker-compose.yml ]; then
    docker compose stop server 2>/dev/null || true
    echo "✅ Containers parados"
else
    echo "⚠️  docker-compose.yml não encontrado, pulando parada de containers"
fi

# Remover pasta antiga
echo ""
echo "🗑️  Removendo código antigo..."
cd ~
if [ -d terafy ]; then
    rm -rf terafy
    echo "✅ Código antigo removido"
else
    echo "⚠️  Pasta terafy não existe, pulando remoção"
fi

# Extrair novo código
echo ""
echo "📦 Extraindo novo código..."
if [ -f terafy.tar.gz ]; then
    tar -xzf terafy.tar.gz
    echo "✅ Código extraído"
else
    echo "❌ Arquivo terafy.tar.gz não encontrado!"
    exit 1
fi

# Rebuild e restart
echo ""
echo "🔨 Rebuild do servidor..."
cd ~/terafy/docker
docker compose build server

echo ""
echo "🚀 Reiniciando servidor..."
docker compose stop server 2>/dev/null || true
docker compose up -d server

echo ""
echo "⏳ Aguardando servidor iniciar..."
sleep 5

# Verificar status
echo ""
echo "📊 Verificando status dos containers..."
docker compose ps

# Testar servidor
echo ""
echo "🧪 Testando servidor..."
if curl -s http://localhost:8080/ping | grep -q "pong"; then
    echo "✅ Servidor está funcionando!"
    echo ""
    echo "📝 Verificar logs:"
    echo "   docker compose logs -f server"
else
    echo "❌ Servidor não respondeu. Verifique os logs:"
    echo "   docker compose logs server"
    exit 1
fi

echo ""
echo "✅ Atualização concluída com sucesso!"


#!/bin/bash
# Script para compilar localmente e enviar binário para a VM
# Uso: ./build-and-deploy.sh [VM_NAME]

set -e

VM_NAME=${1:-terafy-freetier-vm}
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
BUILD_DIR="$DOCKER_DIR/build"

echo "🔨 Compilando servidor localmente..."
echo ""

# 1. Compilar o servidor
cd "$PROJECT_ROOT/server"
echo "📦 Compilando binário..."
dart compile exe bin/server.dart -o "$BUILD_DIR/server"

if [ ! -f "$BUILD_DIR/server" ]; then
    echo "❌ Erro: Falha ao compilar o servidor"
    exit 1
fi

echo "✅ Binário compilado: $BUILD_DIR/server"
ls -lh "$BUILD_DIR/server"

# 2. Copiar migrations
echo ""
echo "📄 Copiando migrations..."
mkdir -p "$BUILD_DIR/migrations"
cp -r "$PROJECT_ROOT/server/db/migrations"/* "$BUILD_DIR/migrations/"
echo "✅ Migrations copiadas"

# 3. Copiar arquivos necessários do docker
echo ""
echo "📋 Copiando arquivos Docker..."
cp "$DOCKER_DIR/docker-compose.runtime.yml" "$BUILD_DIR/docker-compose.yml"
cp "$DOCKER_DIR/Dockerfile.runtime" "$BUILD_DIR/Dockerfile"
cp "$DOCKER_DIR/env.example" "$BUILD_DIR/" 2>/dev/null || true
cp "$DOCKER_DIR/nginx.conf" "$BUILD_DIR/" 2>/dev/null || true

# 4. Criar arquivo tar.gz apenas com o necessário
echo ""
echo "📦 Criando pacote para deploy..."
cd "$BUILD_DIR"
tar -czf "$DOCKER_DIR/terafy-deploy.tar.gz" \
    server \
    migrations/ \
    docker-compose.yml \
    Dockerfile \
    env.example \
    nginx.conf 2>/dev/null || true

echo "✅ Pacote criado: $DOCKER_DIR/terafy-deploy.tar.gz"
ls -lh "$DOCKER_DIR/terafy-deploy.tar.gz"

# 5. Enviar para VM
echo ""
echo "🚀 Enviando para VM: $VM_NAME"
gcloud compute scp "$DOCKER_DIR/terafy-deploy.tar.gz" "$VM_NAME:~/"

echo ""
echo "✅ Deploy package enviado!"
echo ""
echo "📝 Próximos passos na VM:"
echo "   1. cd ~"
echo "   2. mkdir -p terafy-deploy && cd terafy-deploy"
echo "   3. tar -xzf ~/terafy-deploy.tar.gz"
echo "   4. cp env.example .env  # se necessário (editar valores)"
echo "   5. docker compose build server"
echo "   6. docker compose up -d"
echo ""
echo "   Ou use o script update-binario.sh na VM (se disponível)"


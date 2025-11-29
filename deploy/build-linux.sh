#!/bin/bash
# Script para compilar servidor Dart no Mac e gerar binário Linux
# Usa Docker para garantir compilação cross-platform correta
# Uso: ./build-linux.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEW_DEPLOY_DIR="$PROJECT_ROOT/deploy"
BUILD_DIR="$NEW_DEPLOY_DIR/build"
OUTPUT_BINARY="$BUILD_DIR/server"

echo "🐳 Compilando servidor usando Docker (Linux)..."
echo ""

# Criar diretório de build
mkdir -p "$BUILD_DIR"

# Limpar build anterior se existir
rm -f "$OUTPUT_BINARY"

# Build usando Docker
# O Dockerfile.build compila em Linux e gera o binário
# Forçar plataforma linux/amd64 para garantir compatibilidade
echo "📦 Compilando binário Linux (amd64)..."
cd "$PROJECT_ROOT"

docker build \
  --platform linux/amd64 \
  -f "$NEW_DEPLOY_DIR/Dockerfile.build" \
  --target build \
  -t terafy-build:latest \
  .

# Extrair o binário do container
echo ""
echo "📤 Extraindo binário do container..."
CONTAINER_ID=$(docker create terafy-build:latest)
docker cp "$CONTAINER_ID:/app/server/server" "$OUTPUT_BINARY"
docker rm "$CONTAINER_ID"

# Verificar se o binário foi gerado
if [ ! -f "$OUTPUT_BINARY" ]; then
    echo "❌ Erro: Falha ao extrair o binário"
    exit 1
fi

# Tornar executável
chmod +x "$OUTPUT_BINARY"

echo "✅ Binário Linux compilado: $OUTPUT_BINARY"
ls -lh "$OUTPUT_BINARY"

# Verificar arquitetura do binário
echo ""
echo "🔍 Verificando arquitetura do binário..."
if command -v file &> /dev/null; then
    file "$OUTPUT_BINARY"
fi

echo ""
echo "✅ Build concluído com sucesso!"


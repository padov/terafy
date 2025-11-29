#!/bin/bash
# Script para renovar certificados SSL do Let's Encrypt
# Este script pode ser executado manualmente ou via cron para renovação automática

set -e

DEPLOY_DIR="$HOME/terafy-deploy"

echo "🔄 Renovando certificados SSL do Let's Encrypt..."
echo ""

# Verificar se está no diretório correto
if [ ! -f "$DEPLOY_DIR/docker-compose.yml" ]; then
    echo "❌ Erro: docker-compose.yml não encontrado em $DEPLOY_DIR"
    exit 1
fi

cd "$DEPLOY_DIR"

# Renovar certificados
echo "🔐 Tentando renovar certificados..."
docker compose run --rm certbot renew

# Recarregar Nginx se algum certificado foi renovado
echo ""
echo "🔄 Recarregando Nginx..."
docker compose exec nginx nginx -s reload || docker compose restart nginx

echo ""
echo "✅ Renovação concluída!"


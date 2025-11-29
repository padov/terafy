#!/bin/bash
# Script para renovação automática de certificados SSL
# Este script deve ser executado via cron ou systemd timer

set -e

DEPLOY_DIR="$HOME/terafy-deploy"

cd "$DEPLOY_DIR"

# Renovar certificados
docker compose run --rm certbot renew --quiet

# Recarregar Nginx se algum certificado foi renovado
if docker compose ps | grep -q "terafy_nginx.*Up"; then
    docker compose exec nginx nginx -s reload 2>/dev/null || docker compose restart nginx
fi


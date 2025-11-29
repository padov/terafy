#!/bin/bash
# Script para obter certificados SSL do Let's Encrypt usando Certbot
# Uso: Execute na VM após configurar o DNS e antes de iniciar o Nginx com HTTPS

set -e

DEPLOY_DIR="$HOME/terafy-deploy"
EMAIL="${CERTBOT_EMAIL:-admin@terafy.app.br}"  # Email para notificações do Let's Encrypt

echo "🔐 Obtendo certificados SSL do Let's Encrypt..."
echo ""

# Verificar se está no diretório correto
if [ ! -f "$DEPLOY_DIR/docker-compose.yml" ]; then
    echo "❌ Erro: docker-compose.yml não encontrado em $DEPLOY_DIR"
    echo "   Execute este script a partir de ~/terafy-deploy/"
    exit 1
fi

cd "$DEPLOY_DIR"

# Verificar se certificados já existem
if docker compose exec nginx test -d /etc/letsencrypt/live/api.terafy.app.br 2>/dev/null; then
    echo "⚠️  Certificados já existem!"
    read -p "Deseja forçar renovação? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
fi

# Usar nginx.conf temporário (só HTTP) se certificados não existem
if [ ! -f "$DEPLOY_DIR/nginx.conf.temp" ]; then
    echo "⚠️  nginx.conf.temp não encontrado. Usando nginx.conf atual."
    echo "   Se o Nginx falhar ao iniciar, crie um nginx.conf temporário sem HTTPS."
else
    echo "📋 Usando nginx.conf temporário (só HTTP) para obter certificados..."
    cp "$DEPLOY_DIR/nginx.conf" "$DEPLOY_DIR/nginx.conf.backup"
    cp "$DEPLOY_DIR/nginx.conf.temp" "$DEPLOY_DIR/nginx.conf"
    # Atualizar volume do Nginx
    docker compose stop nginx 2>/dev/null || true
    docker compose rm -f nginx 2>/dev/null || true
fi

# Verificar se o Nginx está rodando (necessário para o desafio ACME)
if ! docker compose ps | grep -q "terafy_nginx.*Up"; then
    echo "⚠️  Nginx não está rodando. Iniciando Nginx temporariamente..."
    docker compose --profile with-nginx up -d nginx
    echo "⏳ Aguardando Nginx iniciar..."
    sleep 5
fi

# Criar diretório para desafio ACME se não existir
docker compose exec nginx mkdir -p /var/www/certbot 2>/dev/null || true

# Domínios para obter certificados
DOMAINS=(
    "api.terafy.app.br"
    "app.terafy.app.br"
    "www.terafy.app.br"
    "terafy.app.br"
)

echo "📋 Domínios que serão configurados:"
for domain in "${DOMAINS[@]}"; do
    echo "   - $domain"
done
echo ""

# Obter certificado para cada domínio
for domain in "${DOMAINS[@]}"; do
    echo "🔐 Obtendo certificado para $domain..."
    
    # Usar certonly com webroot para não precisar parar o Nginx
    docker compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$domain" || {
        echo "⚠️  Erro ao obter certificado para $domain"
        echo "   Verifique se o DNS está configurado corretamente"
        continue
    }
    
    echo "✅ Certificado obtido para $domain"
    echo ""
done

# Restaurar nginx.conf completo (com HTTPS) se usamos o temporário
if [ -f "$DEPLOY_DIR/nginx.conf.backup" ]; then
    echo "🔄 Restaurando nginx.conf completo (com HTTPS)..."
    cp "$DEPLOY_DIR/nginx.conf.backup" "$DEPLOY_DIR/nginx.conf"
    rm "$DEPLOY_DIR/nginx.conf.backup"
    # Recriar container do Nginx para montar o novo nginx.conf
    docker compose stop nginx
    docker compose rm -f nginx
    docker compose --profile with-nginx up -d nginx
    echo "⏳ Aguardando Nginx reiniciar com HTTPS..."
    sleep 5
else
    # Recarregar Nginx para usar os novos certificados
    echo "🔄 Recarregando Nginx para usar os certificados SSL..."
    docker compose exec nginx nginx -s reload || docker compose restart nginx
fi

echo ""
echo "✅ Certificados SSL configurados com sucesso!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Verifique se os certificados foram criados:"
echo "      docker compose exec certbot ls -la /etc/letsencrypt/live/"
echo ""
echo "   2. Teste o acesso HTTPS:"
echo "      curl -I https://api.terafy.app.br/ping"
echo "      curl -I https://app.terafy.app.br"
echo ""
echo "   3. Configure renovação automática (já incluída no docker-compose.yml)"
echo ""


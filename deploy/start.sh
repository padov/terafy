#!/bin/bash
# Script de inicialização rápida do ambiente Docker

set -e

echo "🚀 Iniciando ambiente Terafy..."

# Verifica se o arquivo .env existe
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env a partir do template..."
    cp env.example .env
    echo "⚠️  IMPORTANTE: Edite o arquivo .env e configure:"
    echo "   - DB_PASSWORD: Senha do PostgreSQL"
    echo "   - JWT_SECRET_KEY: Chave secreta para JWT"
    echo ""
    echo "Pressione Enter após configurar o .env para continuar..."
    read
fi

# Carrega variáveis de ambiente
export $(cat .env | grep -v '^#' | xargs)

# Verifica se JWT_SECRET_KEY está configurado
if [ -z "$JWT_SECRET_KEY" ] || [ "$JWT_SECRET_KEY" = "sua-chave-secreta-super-segura-aqui-mude-em-producao" ]; then
    echo "⚠️  ATENÇÃO: JWT_SECRET_KEY não foi configurado!"
    echo "   Gere uma chave segura com:"
    echo "   openssl rand -base64 64"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

echo "🔨 Construindo imagens..."
docker compose build

echo "🚀 Iniciando containers..."
docker compose up -d

echo "⏳ Aguardando banco de dados ficar pronto..."
sleep 5

echo "📦 Verificando se migrations foram executadas..."
# Verifica se a tabela users existe (primeira migration)
if docker compose exec -T postgres_db psql -U ${DB_USER:-postgres} -d ${DB_NAME:-terafy_db} -c "\dt" 2>/dev/null | grep -q "users"; then
    echo "✅ Migrations já foram executadas"
else
    echo "📄 Executando migrations..."
    ./run-migrations.sh
fi

echo ""
echo "✅ Ambiente iniciado com sucesso!"
echo ""
echo "📊 Status dos serviços:"
docker compose ps
echo ""
echo "🌐 Servidor disponível em:"
echo "   http://localhost:${SERVER_PORT:-8080}"
echo ""
echo "📝 Comandos úteis:"
echo "   Ver logs: docker compose logs -f"
echo "   Parar: docker compose stop"
echo "   Testar: curl http://localhost:${SERVER_PORT:-8080}/ping"


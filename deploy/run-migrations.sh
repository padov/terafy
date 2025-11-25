#!/bin/bash
# Script para executar migrations no banco de dados

set -e

echo "🔄 Executando migrations no banco de dados..."

# Carrega variáveis de ambiente do .env se existir
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

DB_HOST=${DB_HOST:-postgres_db}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-terafy_db}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-mysecretpassword}

# Lista de migrations na ordem correta
MIGRATIONS=(
    "001_create_users_table.sql"
    "002_create_refresh_tokens_table.sql"
    "003_create_token_blacklist_table.sql"
    "004_create_therapists_table.sql"
    "005_create_plans_and_subscriptions.sql"
    "006_create_patients_table.sql"
    "007_create_therapist_schedule.sql"
    "008_create_sessions_table.sql"
    "009_create_financial_transactions.sql"
)

echo "📊 Conectando ao banco: $DB_HOST:$DB_PORT/$DB_NAME"

# Executa cada migration
for migration in "${MIGRATIONS[@]}"; do
    migration_file="../server/db/migrations/$migration"
    
    if [ ! -f "$migration_file" ]; then
        echo "⚠️  Migration não encontrada: $migration"
        continue
    fi
    
    echo "📄 Executando: $migration"
    
    # Extrai apenas a seção migrate:up
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
\set ON_ERROR_STOP on
$(sed -n '/-- migrate:up/,/-- migrate:down/p' "$migration_file" | sed '/-- migrate:down/d' | sed '/-- migrate:up/d')
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ $migration executada com sucesso"
    else
        echo "   ❌ Erro ao executar $migration"
        exit 1
    fi
done

echo "✅ Todas as migrations foram executadas com sucesso!"


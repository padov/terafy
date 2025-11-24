-- migrate:up

-- Tabela para controlar quais migrations já foram executadas
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índice para melhorar performance de consultas
CREATE INDEX IF NOT EXISTS idx_schema_migrations_executed_at ON schema_migrations(executed_at);

-- migrate:down

DROP TABLE IF EXISTS schema_migrations;


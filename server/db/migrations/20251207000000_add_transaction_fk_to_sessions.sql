-- migrate:up

-- 1. Adicionar coluna transaction_id (nullable inicialmente)
ALTER TABLE sessions
ADD COLUMN transaction_id INTEGER NULL;

-- 2. Criar FK para financial_transactions
ALTER TABLE sessions
ADD CONSTRAINT fk_sessions_transaction
FOREIGN KEY (transaction_id)
REFERENCES financial_transactions(id)
ON DELETE SET NULL;

-- 3. Criar índice
CREATE INDEX idx_sessions_transaction_id ON sessions(transaction_id);

-- 4. Remover coluna payment_status
ALTER TABLE sessions
DROP COLUMN IF EXISTS payment_status;

-- 5. Remover ENUM payment_status
DROP TYPE IF EXISTS payment_status;

-- migrate:down

-- Recriar ENUM
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'exempt');

-- Recriar coluna
ALTER TABLE sessions
ADD COLUMN payment_status payment_status NOT NULL DEFAULT 'pending';

-- Remover FK
DROP INDEX IF EXISTS idx_sessions_transaction_id;
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS fk_sessions_transaction;
ALTER TABLE sessions DROP COLUMN IF EXISTS transaction_id;

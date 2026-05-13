-- migrate:up

-- Adiciona campos para armazenar informações do Google Play Billing
ALTER TABLE plan_subscriptions
  ADD COLUMN IF NOT EXISTS play_store_purchase_token VARCHAR(500),
  ADD COLUMN IF NOT EXISTS play_store_order_id VARCHAR(255),
  ADD COLUMN IF NOT EXISTS auto_renewing BOOLEAN NOT NULL DEFAULT FALSE;

-- Cria índices para busca rápida
CREATE INDEX IF NOT EXISTS idx_plan_subscriptions_play_store_order_id ON plan_subscriptions(play_store_order_id);
CREATE INDEX IF NOT EXISTS idx_plan_subscriptions_play_store_token ON plan_subscriptions(play_store_purchase_token);

-- migrate:down

-- Remove os campos adicionados
ALTER TABLE plan_subscriptions
  DROP COLUMN IF EXISTS play_store_purchase_token,
  DROP COLUMN IF EXISTS play_store_order_id,
  DROP COLUMN IF EXISTS auto_renewing;

DROP INDEX IF EXISTS idx_plan_subscriptions_play_store_order_id;
DROP INDEX IF EXISTS idx_plan_subscriptions_play_store_token;


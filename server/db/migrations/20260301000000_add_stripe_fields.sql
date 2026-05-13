-- migrate:up
ALTER TABLE plans 
ADD COLUMN IF NOT EXISTS stripe_price_id VARCHAR(100);

ALTER TABLE plan_subscriptions
ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS stripe_subscription_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS stripe_status VARCHAR(50);

-- migrate:down
ALTER TABLE plan_subscriptions
DROP COLUMN IF EXISTS stripe_customer_id,
DROP COLUMN IF EXISTS stripe_subscription_id,
DROP COLUMN IF EXISTS stripe_status;

ALTER TABLE plans
DROP COLUMN IF EXISTS stripe_price_id;

-- migrate:up

-- Remove tipo ENUM antigo que não é mais necessário (se existir)
DROP TYPE IF EXISTS subscription_plan;

-- Cria um tipo ENUM para as formas de pagamento
CREATE TYPE payment_method AS ENUM ('credit_card', 'pix', 'bank_slip');

-- Cria a tabela de registro de assinaturas
CREATE TABLE plan_subscriptions (
    id SERIAL PRIMARY KEY,
    therapist_id INT NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    plan_id INT NOT NULL REFERENCES plans(id),
    start_date  TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date  TIMESTAMP WITH TIME ZONE NOT NULL,
    payment_method payment_method NOT NULL,
    payment_details JSONB, -- Para guardar ID da transação, etc.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- migrate:down

DROP TABLE IF EXISTS plan_subscriptions;
DROP TYPE IF EXISTS payment_method;


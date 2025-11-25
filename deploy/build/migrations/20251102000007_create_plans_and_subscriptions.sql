-- migrate:up

-- 1. Cria a tabela para definir os planos
CREATE TABLE plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    patient_limit INT NOT NULL,
    features TEXT[], -- Array de strings para listar os benefícios
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 2. Cria um tipo ENUM para as formas de pagamento
-- Remove primeiro se existir (útil para reexecutar migrations)
DROP TYPE IF EXISTS payment_method CASCADE;
CREATE TYPE payment_method AS ENUM ('credit_card', 'pix', 'bank_slip');

-- 3. Cria a tabela de registro de assinaturas
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

-- 4. Remove o tipo ENUM antigo que não é mais necessário
DROP TYPE IF EXISTS subscription_plan;


-- migrate:down

-- 1. Remove as tabelas novas
DROP TABLE IF EXISTS plan_subscriptions;
DROP TABLE IF EXISTS plans;

-- 4. Remove o tipo ENUM de forma de pagamento
DROP TYPE IF EXISTS payment_method;


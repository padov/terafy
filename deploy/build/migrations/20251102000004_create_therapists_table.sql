-- migrate:up

-- Cria a tabela principal de terapeutas
CREATE TABLE therapists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    document VARCHAR(14) UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    birth_date DATE,
    profile_picture_url TEXT,
    professional_registry_type VARCHAR(20), -- Ex: 'CRP', 'CRM'
    professional_registry_number VARCHAR(30),
    specialties TEXT[], -- Array de strings
    education TEXT,
    professional_presentation TEXT,
    office_address TEXT,
    calendar_settings JSONB,
    notification_preferences JSONB,
    bank_details JSONB, -- ATENÇÃO: Dados sensíveis devem ser criptografados na aplicação
    status account_status NOT NULL DEFAULT 'active',
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- migrate:down

-- Remove a tabela de terapeutas e os tipos enum
DROP TABLE IF EXISTS therapists;
DROP TYPE IF EXISTS subscription_plan;
DROP TYPE IF EXISTS account_status;


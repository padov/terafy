-- migrate:up

-- Cria a tabela principal de terapeutas
CREATE TABLE therapists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    nickname VARCHAR(100),
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
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Índice para performance na foreign key user_id
CREATE INDEX idx_therapists_user_id ON therapists(user_id);

-- Habilita Row Level Security (RLS) na tabela therapists
ALTER TABLE therapists ENABLE ROW LEVEL SECURITY;

-- migrate:down

-- Remove a tabela de terapeutas
DROP TABLE IF EXISTS therapists;


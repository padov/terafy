-- migrate:up

-- Cria tipo ENUM para status de pacientes
CREATE TYPE patient_status AS ENUM ('active', 'inactive', 'discharged', 'completed', 'evaluated');

-- Cria a tabela de pacientes vinculados a um terapeuta
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL DEFAULT (current_setting('app.account_id', true)::int) REFERENCES therapists(id) ON DELETE CASCADE,
    user_id INTEGER UNIQUE REFERENCES users(id),
    full_name VARCHAR(255) NOT NULL,
    birth_date DATE,
    age SMALLINT,
    cpf VARCHAR(14) UNIQUE,
    rg VARCHAR(20),
    gender VARCHAR(20),
    marital_status VARCHAR(30),
    address TEXT,
    email VARCHAR(255),
    phones TEXT[] DEFAULT ARRAY[]::TEXT[],
    profession VARCHAR(255),
    education VARCHAR(255),
    emergency_contact JSONB,
    legal_guardian JSONB,
    health_insurance VARCHAR(255),
    health_insurance_card VARCHAR(100),
    preferred_payment_method VARCHAR(50),
    session_price NUMERIC(10, 2),
    consent_signed_at  TIMESTAMP WITH TIME ZONE,
    lgpd_consent_at  TIMESTAMP WITH TIME ZONE,
    status patient_status NOT NULL DEFAULT 'active',
    inactivation_reason TEXT,
    treatment_start_date DATE,
    last_session_date DATE,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    notes TEXT,
    photo_url TEXT,
    color VARCHAR(20),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_session_price_positive CHECK (session_price IS NULL OR session_price >= 0),
    CONSTRAINT chk_total_sessions_non_negative CHECK (total_sessions >= 0)
);

CREATE INDEX idx_patients_therapist_id ON patients(therapist_id);
CREATE INDEX idx_patients_status ON patients(status);
CREATE INDEX idx_patients_tags ON patients USING GIN (tags);

-- Habilita Row Level Security (RLS) na tabela patients
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- migrate:down

DROP INDEX IF EXISTS idx_patients_tags;
DROP INDEX IF EXISTS idx_patients_status;
DROP INDEX IF EXISTS idx_patients_therapist_id;
DROP TABLE IF EXISTS patients;
DROP TYPE IF EXISTS patient_status;


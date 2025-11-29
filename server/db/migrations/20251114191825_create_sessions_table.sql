-- migrate:up

-- Cria tipos ENUM para sessões
CREATE TYPE session_type AS ENUM ('presential', 'onlineVideo', 'onlineAudio', 'phone', 'group');
CREATE TYPE session_modality AS ENUM ('individual', 'couple', 'family', 'group');
CREATE TYPE session_status AS ENUM ('scheduled', 'confirmed', 'inProgress', 'completed', 'draft', 'cancelledByTherapist', 'cancelledByPatient', 'noShow');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'exempt');
CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high');

-- Cria a tabela de sessões
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    appointment_id INTEGER NULL REFERENCES appointments(id) ON DELETE SET NULL,
    scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER NOT NULL,
    session_number INTEGER NOT NULL,
    type session_type NOT NULL DEFAULT 'presential',
    modality session_modality NOT NULL DEFAULT 'individual',
    location VARCHAR(255),
    online_room_link TEXT,
    status session_status NOT NULL DEFAULT 'scheduled',
    cancellation_reason TEXT,
    cancellation_time TIMESTAMP WITH TIME ZONE,
    charged_amount NUMERIC(10, 2),
    payment_status payment_status NOT NULL DEFAULT 'pending',
    -- Campos de registro clínico
    patient_mood TEXT,
    topics_discussed JSONB DEFAULT '[]'::jsonb,
    session_notes TEXT,
    observed_behavior TEXT,
    interventions_used JSONB DEFAULT '[]'::jsonb,
    resources_used TEXT,
    homework TEXT,
    patient_reactions TEXT,
    progress_observed TEXT,
    difficulties_identified TEXT,
    next_steps TEXT,
    next_session_goals TEXT,
    needs_referral BOOLEAN DEFAULT FALSE,
    current_risk risk_level DEFAULT 'low',
    important_observations TEXT,
    -- Campos de dados administrativos
    presence_confirmation_time TIMESTAMP WITH TIME ZONE,
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_time TIMESTAMP WITH TIME ZONE,
    patient_rating INTEGER CHECK (patient_rating IS NULL OR (patient_rating >= 1 AND patient_rating <= 5)),
    attachments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_duration_positive CHECK (duration_minutes > 0),
    CONSTRAINT chk_session_number_positive CHECK (session_number > 0),
    CONSTRAINT chk_charged_amount_positive CHECK (charged_amount IS NULL OR charged_amount >= 0),
    CONSTRAINT chk_session_times CHECK (scheduled_end_time IS NULL OR scheduled_start_time < scheduled_end_time)
);

-- Índices para performance
CREATE INDEX idx_sessions_patient_id ON sessions(patient_id);
CREATE INDEX idx_sessions_therapist_id ON sessions(therapist_id);
CREATE INDEX idx_sessions_appointment_id ON sessions(appointment_id);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_scheduled_start_time ON sessions(scheduled_start_time);

-- Triggers serão criados via scripts em triggers/sessions_triggers.sql

-- Adiciona coluna session_id na tabela appointments se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'session_id'
    ) THEN
        ALTER TABLE appointments
        ADD COLUMN session_id INTEGER NULL;
        
        ALTER TABLE appointments
        ADD CONSTRAINT fk_appointments_session
        FOREIGN KEY (session_id)
        REFERENCES sessions(id)
        ON DELETE SET NULL;
        
        CREATE INDEX idx_appointments_session_id ON appointments(session_id);
    END IF;
END $$;

-- migrate:down

-- Functions e triggers são gerenciados via pastas functions/ e triggers/

DROP INDEX IF EXISTS idx_appointments_session_id;
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS fk_appointments_session;
ALTER TABLE appointments DROP COLUMN IF EXISTS session_id;

DROP INDEX IF EXISTS idx_sessions_scheduled_start_time;
DROP INDEX IF EXISTS idx_sessions_status;
DROP INDEX IF EXISTS idx_sessions_appointment_id;
DROP INDEX IF EXISTS idx_sessions_therapist_id;
DROP INDEX IF EXISTS idx_sessions_patient_id;

DROP TABLE IF EXISTS sessions;

DROP TYPE IF EXISTS risk_level;
DROP TYPE IF EXISTS payment_status;
DROP TYPE IF EXISTS session_status;
DROP TYPE IF EXISTS session_modality;
DROP TYPE IF EXISTS session_type;


-- migrate:up

-- Cria tipos ENUM para sessões
CREATE TYPE session_type AS ENUM ('presential', 'onlineVideo', 'onlineAudio', 'phone', 'group');
CREATE TYPE session_modality AS ENUM ('individual', 'couple', 'family', 'group');
CREATE TYPE session_status AS ENUM ('scheduled', 'confirmed', 'inProgress', 'completed', 'draft', 'cancelledByTherapist', 'cancelledByPatient', 'noShow');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'exempt');

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

-- Trigger para calcular session_number automaticamente (sequencial por paciente)
CREATE OR REPLACE FUNCTION calculate_session_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Se session_number não foi fornecido ou é 0, calcular automaticamente
    IF NEW.session_number IS NULL OR NEW.session_number = 0 THEN
        SELECT COALESCE(MAX(session_number), 0) + 1
        INTO NEW.session_number
        FROM sessions
        WHERE patient_id = NEW.patient_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_session_number
BEFORE INSERT ON sessions
FOR EACH ROW
EXECUTE FUNCTION calculate_session_number();

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION update_sessions_updated_at();

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

DROP TRIGGER IF EXISTS trg_update_sessions_updated_at ON sessions;
DROP FUNCTION IF EXISTS update_sessions_updated_at();

DROP TRIGGER IF EXISTS trg_calculate_session_number ON sessions;
DROP FUNCTION IF EXISTS calculate_session_number();

DROP INDEX IF EXISTS idx_appointments_session_id;
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS fk_appointments_session;
ALTER TABLE appointments DROP COLUMN IF EXISTS session_id;

DROP INDEX IF EXISTS idx_sessions_scheduled_start_time;
DROP INDEX IF EXISTS idx_sessions_status;
DROP INDEX IF EXISTS idx_sessions_appointment_id;
DROP INDEX IF EXISTS idx_sessions_therapist_id;
DROP INDEX IF EXISTS idx_sessions_patient_id;

DROP TABLE IF EXISTS sessions;

DROP TYPE IF EXISTS payment_status;
DROP TYPE IF EXISTS session_status;
DROP TYPE IF EXISTS session_modality;
DROP TYPE IF EXISTS session_type;


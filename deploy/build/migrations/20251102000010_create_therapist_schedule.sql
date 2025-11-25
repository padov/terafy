-- migrate:up

-- Tipos auxiliares
CREATE TYPE appointment_type AS ENUM ('session', 'personal', 'block');
CREATE TYPE appointment_status AS ENUM (
  'available',
  'reserved',
  'confirmed',
  'completed',
  'cancelled'
);
CREATE TYPE reminder_channel AS ENUM ('email', 'sms', 'whatsapp', 'push');
CREATE TYPE reminder_offset AS ENUM ('24h', '48h', '1week');

-- Configurações de agenda por terapeuta
CREATE TABLE therapist_schedule_settings (
    therapist_id INTEGER PRIMARY KEY REFERENCES therapists(id) ON DELETE CASCADE,
    working_hours JSONB NOT NULL DEFAULT '{}'::JSONB,
    session_duration_minutes INTEGER NOT NULL DEFAULT 50,
    break_minutes INTEGER NOT NULL DEFAULT 10,
    locations TEXT[] DEFAULT ARRAY[]::TEXT[],
    days_off DATE[] DEFAULT ARRAY[]::DATE[],
    holidays DATE[] DEFAULT ARRAY[]::DATE[],
    custom_blocks JSONB DEFAULT '[]'::JSONB,
    reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    reminder_default_offset reminder_offset NOT NULL DEFAULT '24h',
    reminder_default_channel reminder_channel NOT NULL DEFAULT 'email',
    cancellation_policy JSONB DEFAULT '{}'::JSONB,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Agendamentos
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES patients(id),
    type appointment_type NOT NULL DEFAULT 'session',
    status appointment_status NOT NULL DEFAULT 'reserved',
    title VARCHAR(255),
    description TEXT,
    start_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    recurrence_rule JSONB,
    recurrence_end  TIMESTAMP WITH TIME ZONE,
    recurrence_exceptions  TIMESTAMP WITH TIME ZONE[] DEFAULT ARRAY[]:: TIMESTAMP WITH TIME ZONE[],
    location VARCHAR(255),
    online_link TEXT,
    color VARCHAR(20),
    reminders JSONB DEFAULT '[]'::JSONB,
    reminder_sent_at  TIMESTAMP WITH TIME ZONE,
    patient_confirmed_at  TIMESTAMP WITH TIME ZONE,
    patient_arrival_at  TIMESTAMP WITH TIME ZONE,
    waiting_room_status VARCHAR(20),
    cancellation_reason TEXT,
    notes TEXT,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_appointment_times CHECK (start_time < end_time)
);

CREATE INDEX idx_appointments_therapist_start ON appointments(therapist_id, start_time);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_type ON appointments(type);

-- migrate:down

DROP INDEX IF EXISTS idx_appointments_type;
DROP INDEX IF EXISTS idx_appointments_status;
DROP INDEX IF EXISTS idx_appointments_patient;
DROP INDEX IF EXISTS idx_appointments_therapist_start;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS therapist_schedule_settings;
DROP TYPE IF EXISTS reminder_offset;
DROP TYPE IF EXISTS reminder_channel;
DROP TYPE IF EXISTS appointment_status;
DROP TYPE IF EXISTS appointment_type;


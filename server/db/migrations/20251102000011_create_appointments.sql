-- migrate:up

-- Tipos auxiliares para agendamentos
CREATE TYPE appointment_type AS ENUM ('session', 'personal', 'block');
CREATE TYPE appointment_status AS ENUM (
  'reserved',
  'confirmed',
  'completed',
  'cancelled'
);

-- Agendamentos
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES patients(id),
    parent_appointment_id INTEGER REFERENCES appointments(id) ON DELETE SET NULL,
    type appointment_type NOT NULL DEFAULT 'session',
    status appointment_status NOT NULL DEFAULT 'reserved',
    title VARCHAR(255),
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    recurrence_rule JSONB,
    recurrence_end TIMESTAMP WITH TIME ZONE,
    recurrence_exceptions TIMESTAMP WITH TIME ZONE[] DEFAULT ARRAY[]::TIMESTAMP WITH TIME ZONE[],
    location VARCHAR(255),
    online_link TEXT,
    color VARCHAR(20),
    reminders JSONB DEFAULT '[]'::JSONB,
    reminder_sent_at TIMESTAMP WITH TIME ZONE,
    patient_confirmed_at TIMESTAMP WITH TIME ZONE,
    patient_arrival_at TIMESTAMP WITH TIME ZONE,
    waiting_room_status VARCHAR(20),
    cancellation_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_appointment_times CHECK (start_time < end_time)
);

-- Índices para performance
CREATE INDEX idx_appointments_therapist_start ON appointments(therapist_id, start_time);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_type ON appointments(type);
CREATE INDEX idx_appointments_parent_id ON appointments(parent_appointment_id);

-- migrate:down

DROP INDEX IF EXISTS idx_appointments_type;
DROP INDEX IF EXISTS idx_appointments_status;
DROP INDEX IF EXISTS idx_appointments_patient;
DROP INDEX IF EXISTS idx_appointments_therapist_start;
DROP TABLE IF EXISTS appointments;
DROP TYPE IF EXISTS appointment_status;
DROP TYPE IF EXISTS appointment_type;


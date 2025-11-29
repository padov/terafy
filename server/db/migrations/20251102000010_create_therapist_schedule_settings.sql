-- migrate:up

-- Tipos auxiliares para configurações de agenda
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
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- migrate:down

DROP TABLE IF EXISTS therapist_schedule_settings;
DROP TYPE IF EXISTS reminder_offset;
DROP TYPE IF EXISTS reminder_channel;


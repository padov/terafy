-- migrate:up

-- Cria tipo ENUM para nível de risco
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_level') THEN
        CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high');
    END IF;
END $$;

-- Adiciona colunas de registro clínico
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS patient_mood TEXT,
ADD COLUMN IF NOT EXISTS topics_discussed JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS session_notes TEXT,
ADD COLUMN IF NOT EXISTS observed_behavior TEXT,
ADD COLUMN IF NOT EXISTS interventions_used JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS resources_used TEXT,
ADD COLUMN IF NOT EXISTS homework TEXT,
ADD COLUMN IF NOT EXISTS patient_reactions TEXT,
ADD COLUMN IF NOT EXISTS progress_observed TEXT,
ADD COLUMN IF NOT EXISTS difficulties_identified TEXT,
ADD COLUMN IF NOT EXISTS next_steps TEXT,
ADD COLUMN IF NOT EXISTS next_session_goals TEXT,
ADD COLUMN IF NOT EXISTS needs_referral BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS current_risk risk_level DEFAULT 'low',
ADD COLUMN IF NOT EXISTS important_observations TEXT;

-- Adiciona colunas de dados administrativos
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS presence_confirmation_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS reminder_sent_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS patient_rating INTEGER CHECK (patient_rating IS NULL OR (patient_rating >= 1 AND patient_rating <= 5)),
ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]'::jsonb;

-- migrate:down

ALTER TABLE sessions
DROP COLUMN IF EXISTS attachments,
DROP COLUMN IF EXISTS patient_rating,
DROP COLUMN IF EXISTS reminder_sent_time,
DROP COLUMN IF EXISTS reminder_sent,
DROP COLUMN IF EXISTS presence_confirmation_time,
DROP COLUMN IF EXISTS important_observations,
DROP COLUMN IF EXISTS current_risk,
DROP COLUMN IF EXISTS needs_referral,
DROP COLUMN IF EXISTS next_session_goals,
DROP COLUMN IF EXISTS next_steps,
DROP COLUMN IF EXISTS difficulties_identified,
DROP COLUMN IF EXISTS progress_observed,
DROP COLUMN IF EXISTS patient_reactions,
DROP COLUMN IF EXISTS homework,
DROP COLUMN IF EXISTS resources_used,
DROP COLUMN IF EXISTS interventions_used,
DROP COLUMN IF EXISTS observed_behavior,
DROP COLUMN IF EXISTS session_notes,
DROP COLUMN IF EXISTS topics_discussed,
DROP COLUMN IF EXISTS patient_mood;

DROP TYPE IF EXISTS risk_level;


-- migrate:up
CREATE TABLE anamnesis_invites (
    id SERIAL PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    template_id INTEGER NOT NULL REFERENCES anamnesis_templates(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, used, expired
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT chk_status CHECK (status IN ('pending', 'used', 'expired'))
);

CREATE INDEX idx_anamnesis_invites_token ON anamnesis_invites(token);
CREATE INDEX idx_anamnesis_invites_patient_id ON anamnesis_invites(patient_id);

-- migrate:down
DROP INDEX IF EXISTS idx_anamnesis_invites_patient_id;
DROP INDEX IF EXISTS idx_anamnesis_invites_token;
DROP TABLE IF EXISTS anamnesis_invites;

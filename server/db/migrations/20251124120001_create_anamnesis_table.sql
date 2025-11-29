-- migrate:up

-- Cria a tabela de anamneses (dados preenchidos)
CREATE TABLE anamnesis (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    template_id INTEGER REFERENCES anamnesis_templates(id) ON DELETE SET NULL,
    
    -- Dados estruturados preenchidos (JSONB)
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Metadata
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Garante uma anamnese por paciente
    CONSTRAINT unique_patient_anamnesis UNIQUE(patient_id)
);

CREATE INDEX idx_anamnesis_patient_id ON anamnesis(patient_id);
CREATE INDEX idx_anamnesis_therapist_id ON anamnesis(therapist_id);
CREATE INDEX idx_anamnesis_template_id ON anamnesis(template_id);
CREATE INDEX idx_anamnesis_data ON anamnesis USING GIN (data);
CREATE INDEX idx_anamnesis_completed_at ON anamnesis(completed_at);

-- migrate:down

DROP INDEX IF EXISTS idx_anamnesis_completed_at;
DROP INDEX IF EXISTS idx_anamnesis_data;
DROP INDEX IF EXISTS idx_anamnesis_template_id;
DROP INDEX IF EXISTS idx_anamnesis_therapist_id;
DROP INDEX IF EXISTS idx_anamnesis_patient_id;
DROP TABLE IF EXISTS anamnesis;


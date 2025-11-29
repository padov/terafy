-- migrate:up

-- Cria a tabela de templates de anamnese
CREATE TABLE anamnesis_templates (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER REFERENCES therapists(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'adult', 'child', 'couple', 'family', 'custom'
    is_default BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE, -- Templates do sistema (não deletáveis)
    
    -- Estrutura do template (seções e campos) em JSONB
    structure JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_anamnesis_templates_therapist_id ON anamnesis_templates(therapist_id);
CREATE INDEX idx_anamnesis_templates_category ON anamnesis_templates(category);
CREATE INDEX idx_anamnesis_templates_is_default ON anamnesis_templates(therapist_id, is_default) WHERE is_default = TRUE;
CREATE INDEX idx_anamnesis_templates_structure ON anamnesis_templates USING GIN (structure);

-- Garante que apenas um template padrão por terapeuta (índice único parcial)
CREATE UNIQUE INDEX idx_anamnesis_templates_unique_default 
    ON anamnesis_templates(therapist_id) 
    WHERE is_default = TRUE;

-- migrate:down

DROP INDEX IF EXISTS idx_anamnesis_templates_unique_default;
DROP INDEX IF EXISTS idx_anamnesis_templates_structure;
DROP INDEX IF EXISTS idx_anamnesis_templates_is_default;
DROP INDEX IF EXISTS idx_anamnesis_templates_category;
DROP INDEX IF EXISTS idx_anamnesis_templates_therapist_id;
DROP TABLE IF EXISTS anamnesis_templates;


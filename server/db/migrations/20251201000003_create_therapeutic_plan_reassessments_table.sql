-- migrate:up

-- Cria a tabela de histórico de reavaliações de planos terapêuticos
CREATE TABLE therapeutic_plan_reassessments (
    id SERIAL PRIMARY KEY,
    therapeutic_plan_id INTEGER NOT NULL REFERENCES therapeutic_plans(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    
    -- Data da reavaliação
    reassessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Objetivos processados
    objectives_achieved INTEGER[], -- IDs dos objetivos alcançados
    objectives_in_progress INTEGER[], -- IDs dos objetivos em progresso
    objectives_abandoned INTEGER[], -- IDs dos objetivos abandonados
    
    -- Ajustes realizados
    adjustments_made TEXT, -- Descrição dos ajustes realizados no plano
    new_objectives_added INTEGER[], -- IDs dos novos objetivos adicionados
    
    -- Mudanças no plano
    plan_changes TEXT, -- Descrição das mudanças no plano terapêutico
    
    -- Observações
    observations TEXT, -- Observações gerais da reavaliação
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_therapeutic_plan_reassessments_plan_id ON therapeutic_plan_reassessments(therapeutic_plan_id);
CREATE INDEX idx_therapeutic_plan_reassessments_therapist_id ON therapeutic_plan_reassessments(therapist_id);
CREATE INDEX idx_therapeutic_plan_reassessments_date ON therapeutic_plan_reassessments(reassessment_date);

-- Índices GIN para arrays
CREATE INDEX idx_therapeutic_plan_reassessments_objectives_achieved ON therapeutic_plan_reassessments USING GIN (objectives_achieved);
CREATE INDEX idx_therapeutic_plan_reassessments_objectives_in_progress ON therapeutic_plan_reassessments USING GIN (objectives_in_progress);
CREATE INDEX idx_therapeutic_plan_reassessments_objectives_abandoned ON therapeutic_plan_reassessments USING GIN (objectives_abandoned);
CREATE INDEX idx_therapeutic_plan_reassessments_new_objectives ON therapeutic_plan_reassessments USING GIN (new_objectives_added);

-- Habilita RLS
ALTER TABLE therapeutic_plan_reassessments ENABLE ROW LEVEL SECURITY;

-- migrate:down

DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_new_objectives;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_objectives_abandoned;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_objectives_in_progress;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_objectives_achieved;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_date;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_therapist_id;
DROP INDEX IF EXISTS idx_therapeutic_plan_reassessments_plan_id;

DROP TABLE IF EXISTS therapeutic_plan_reassessments;


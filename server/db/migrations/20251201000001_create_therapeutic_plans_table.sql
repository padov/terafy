-- migrate:up

-- Cria tipo ENUM para status do plano terapêutico
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'therapeutic_plan_status') THEN
        CREATE TYPE therapeutic_plan_status AS ENUM ('draft', 'active', 'reviewing', 'completed', 'archived');
    END IF;
END $$;

-- Cria tipo ENUM para abordagem terapêutica
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'therapeutic_approach') THEN
        CREATE TYPE therapeutic_approach AS ENUM (
            'cognitive_behavioral',
            'psychodynamic',
            'humanistic',
            'systemic',
            'existential',
            'gestalt',
            'integrative',
            'other'
        );
    END IF;
END $$;

-- Cria a tabela de planos terapêuticos
CREATE TABLE therapeutic_plans (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    
    -- Abordagem terapêutica
    approach therapeutic_approach NOT NULL,
    approach_other VARCHAR(255), -- Para quando approach = 'other'
    
    -- Informações do plano
    recommended_frequency VARCHAR(100), -- Ex: "Semanal", "Quinzenal", "Mensal"
    session_duration_minutes INTEGER CHECK (session_duration_minutes > 0),
    estimated_duration_months INTEGER CHECK (estimated_duration_months > 0),
    
    -- Estratégias e técnicas
    main_techniques TEXT[], -- Array de técnicas principais
    intervention_strategies TEXT, -- Estratégias de intervenção detalhadas
    resources_to_use TEXT, -- Recursos a serem utilizados
    therapeutic_tasks TEXT, -- Tarefas terapêuticas
    
    -- Monitoramento
    monitoring_indicators JSONB DEFAULT '{}'::jsonb, -- Indicadores de monitoramento estruturados
    assessment_instruments TEXT[], -- Instrumentos de avaliação utilizados
    measurement_frequency VARCHAR(100), -- Frequência de medição
    
    -- Reavaliações programadas
    scheduled_reassessments JSONB DEFAULT '[]'::jsonb, -- Array de reavaliações programadas
    
    -- Observações e recursos
    observations TEXT, -- Observações gerais do plano
    available_resources TEXT, -- Recursos disponíveis para o tratamento
    support_network TEXT, -- Rede de apoio do paciente
    
    -- Status e controle
    status therapeutic_plan_status NOT NULL DEFAULT 'draft',
    reviewed_at TIMESTAMP WITH TIME ZONE, -- Data da última revisão
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    
    -- Constraint: apenas um plano ativo por paciente (será implementada via índice único parcial)
);

-- Índices
CREATE INDEX idx_therapeutic_plans_patient_id ON therapeutic_plans(patient_id);
CREATE INDEX idx_therapeutic_plans_therapist_id ON therapeutic_plans(therapist_id);
CREATE INDEX idx_therapeutic_plans_status ON therapeutic_plans(status);
CREATE INDEX idx_therapeutic_plans_created_at ON therapeutic_plans(created_at);
CREATE INDEX idx_therapeutic_plans_reviewed_at ON therapeutic_plans(reviewed_at);

-- Índice GIN para campos JSONB
CREATE INDEX idx_therapeutic_plans_monitoring_indicators ON therapeutic_plans USING GIN (monitoring_indicators);
CREATE INDEX idx_therapeutic_plans_scheduled_reassessments ON therapeutic_plans USING GIN (scheduled_reassessments);

-- Índice GIN para arrays
CREATE INDEX idx_therapeutic_plans_main_techniques ON therapeutic_plans USING GIN (main_techniques);
CREATE INDEX idx_therapeutic_plans_assessment_instruments ON therapeutic_plans USING GIN (assessment_instruments);

-- Índice único parcial: apenas um plano ativo por paciente
CREATE UNIQUE INDEX idx_therapeutic_plans_unique_active_per_patient 
    ON therapeutic_plans(patient_id) 
    WHERE status = 'active';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_therapeutic_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_therapeutic_plans_updated_at
    BEFORE UPDATE ON therapeutic_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_therapeutic_plans_updated_at();

-- Habilita RLS
ALTER TABLE therapeutic_plans ENABLE ROW LEVEL SECURITY;

-- migrate:down

DROP TRIGGER IF EXISTS trg_update_therapeutic_plans_updated_at ON therapeutic_plans;
DROP FUNCTION IF EXISTS update_therapeutic_plans_updated_at();

DROP INDEX IF EXISTS idx_therapeutic_plans_unique_active_per_patient;
DROP INDEX IF EXISTS idx_therapeutic_plans_assessment_instruments;
DROP INDEX IF EXISTS idx_therapeutic_plans_main_techniques;
DROP INDEX IF EXISTS idx_therapeutic_plans_scheduled_reassessments;
DROP INDEX IF EXISTS idx_therapeutic_plans_monitoring_indicators;
DROP INDEX IF EXISTS idx_therapeutic_plans_reviewed_at;
DROP INDEX IF EXISTS idx_therapeutic_plans_created_at;
DROP INDEX IF EXISTS idx_therapeutic_plans_status;
DROP INDEX IF EXISTS idx_therapeutic_plans_therapist_id;
DROP INDEX IF EXISTS idx_therapeutic_plans_patient_id;

DROP TABLE IF EXISTS therapeutic_plans;

DROP TYPE IF EXISTS therapeutic_approach;
DROP TYPE IF EXISTS therapeutic_plan_status;


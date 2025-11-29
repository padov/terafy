-- migrate:up

-- Cria tipo ENUM para tipo de prazo do objetivo
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'objective_deadline_type') THEN
        CREATE TYPE objective_deadline_type AS ENUM ('short_term', 'medium_term', 'long_term');
    END IF;
END $$;

-- Cria tipo ENUM para prioridade do objetivo
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'objective_priority') THEN
        CREATE TYPE objective_priority AS ENUM ('low', 'medium', 'high', 'urgent');
    END IF;
END $$;

-- Cria tipo ENUM para status do objetivo
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'objective_status') THEN
        CREATE TYPE objective_status AS ENUM ('pending', 'in_progress', 'completed', 'abandoned', 'on_hold');
    END IF;
END $$;

-- Cria a tabela de objetivos terapêuticos
CREATE TABLE therapeutic_objectives (
    id SERIAL PRIMARY KEY,
    therapeutic_plan_id INTEGER NOT NULL REFERENCES therapeutic_plans(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    
    -- Descrição SMART do objetivo
    description TEXT NOT NULL, -- Descrição geral do objetivo
    specific_aspect TEXT NOT NULL, -- Específico: o que exatamente será alcançado
    measurable_criteria TEXT NOT NULL, -- Mensurável: como será medido
    achievable_conditions TEXT, -- Alcançável: condições necessárias
    relevant_justification TEXT, -- Relevante: por que é importante
    time_bound_deadline TEXT, -- Temporal: prazo ou marco temporal
    
    -- Classificação
    deadline_type objective_deadline_type NOT NULL DEFAULT 'medium_term',
    priority objective_priority NOT NULL DEFAULT 'medium',
    status objective_status NOT NULL DEFAULT 'pending',
    
    -- Progresso
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    progress_indicators JSONB DEFAULT '{}'::jsonb, -- Indicadores específicos de progresso
    success_metric TEXT, -- Métrica de sucesso do objetivo
    
    -- Metas mensuráveis
    measurable_goals JSONB DEFAULT '[]'::jsonb, -- Array de metas mensuráveis
    
    -- Intervenções relacionadas
    related_interventions JSONB DEFAULT '[]'::jsonb, -- Intervenções que contribuem para este objetivo
    
    -- Datas
    target_date DATE, -- Data alvo para conclusão
    started_at TIMESTAMP WITH TIME ZONE, -- Quando foi iniciado
    completed_at TIMESTAMP WITH TIME ZONE, -- Quando foi completado
    abandoned_at TIMESTAMP WITH TIME ZONE, -- Quando foi abandonado
    abandoned_reason TEXT, -- Razão do abandono
    
    -- Observações
    notes TEXT, -- Notas adicionais sobre o objetivo
    
    -- Ordem de exibição
    display_order INTEGER DEFAULT 0, -- Ordem de exibição na lista
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_therapeutic_objectives_plan_id ON therapeutic_objectives(therapeutic_plan_id);
CREATE INDEX idx_therapeutic_objectives_patient_id ON therapeutic_objectives(patient_id);
CREATE INDEX idx_therapeutic_objectives_therapist_id ON therapeutic_objectives(therapist_id);
CREATE INDEX idx_therapeutic_objectives_status ON therapeutic_objectives(status);
CREATE INDEX idx_therapeutic_objectives_priority ON therapeutic_objectives(priority);
CREATE INDEX idx_therapeutic_objectives_deadline_type ON therapeutic_objectives(deadline_type);
CREATE INDEX idx_therapeutic_objectives_target_date ON therapeutic_objectives(target_date);
CREATE INDEX idx_therapeutic_objectives_display_order ON therapeutic_objectives(therapeutic_plan_id, display_order);

-- Índices GIN para campos JSONB
CREATE INDEX idx_therapeutic_objectives_progress_indicators ON therapeutic_objectives USING GIN (progress_indicators);
CREATE INDEX idx_therapeutic_objectives_measurable_goals ON therapeutic_objectives USING GIN (measurable_goals);
CREATE INDEX idx_therapeutic_objectives_related_interventions ON therapeutic_objectives USING GIN (related_interventions);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_therapeutic_objectives_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_therapeutic_objectives_updated_at
    BEFORE UPDATE ON therapeutic_objectives
    FOR EACH ROW
    EXECUTE FUNCTION update_therapeutic_objectives_updated_at();

-- Trigger para atualizar status automaticamente baseado em progresso e datas
CREATE OR REPLACE FUNCTION update_therapeutic_objective_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Se foi marcado como completado
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
        NEW.progress_percentage = 100;
        IF NEW.started_at IS NULL THEN
            NEW.started_at = NOW();
        END IF;
    END IF;
    
    -- Se foi marcado como abandonado
    IF NEW.status = 'abandoned' AND OLD.status != 'abandoned' THEN
        NEW.abandoned_at = NOW();
    END IF;
    
    -- Se foi marcado como in_progress e ainda não tinha started_at
    IF NEW.status = 'in_progress' AND OLD.status != 'in_progress' AND NEW.started_at IS NULL THEN
        NEW.started_at = NOW();
    END IF;
    
    -- Atualização automática de status baseado em progresso
    IF NEW.status != 'completed' AND NEW.status != 'abandoned' THEN
        IF NEW.progress_percentage = 0 AND NEW.started_at IS NULL THEN
            NEW.status = 'pending';
        ELSIF NEW.progress_percentage > 0 AND NEW.progress_percentage < 100 THEN
            IF NEW.status = 'pending' THEN
                NEW.status = 'in_progress';
            END IF;
        ELSIF NEW.progress_percentage = 100 THEN
            NEW.status = 'completed';
            NEW.completed_at = COALESCE(NEW.completed_at, NOW());
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_therapeutic_objective_status
    BEFORE INSERT OR UPDATE ON therapeutic_objectives
    FOR EACH ROW
    EXECUTE FUNCTION update_therapeutic_objective_status();

-- Habilita RLS
ALTER TABLE therapeutic_objectives ENABLE ROW LEVEL SECURITY;

-- migrate:down

DROP TRIGGER IF EXISTS trg_update_therapeutic_objective_status ON therapeutic_objectives;
DROP FUNCTION IF EXISTS update_therapeutic_objective_status();

DROP TRIGGER IF EXISTS trg_update_therapeutic_objectives_updated_at ON therapeutic_objectives;
DROP FUNCTION IF EXISTS update_therapeutic_objectives_updated_at();

DROP INDEX IF EXISTS idx_therapeutic_objectives_related_interventions;
DROP INDEX IF EXISTS idx_therapeutic_objectives_measurable_goals;
DROP INDEX IF EXISTS idx_therapeutic_objectives_progress_indicators;
DROP INDEX IF EXISTS idx_therapeutic_objectives_display_order;
DROP INDEX IF EXISTS idx_therapeutic_objectives_target_date;
DROP INDEX IF EXISTS idx_therapeutic_objectives_deadline_type;
DROP INDEX IF EXISTS idx_therapeutic_objectives_priority;
DROP INDEX IF EXISTS idx_therapeutic_objectives_status;
DROP INDEX IF EXISTS idx_therapeutic_objectives_therapist_id;
DROP INDEX IF EXISTS idx_therapeutic_objectives_patient_id;
DROP INDEX IF EXISTS idx_therapeutic_objectives_plan_id;

DROP TABLE IF EXISTS therapeutic_objectives;

DROP TYPE IF EXISTS objective_status;
DROP TYPE IF EXISTS objective_priority;
DROP TYPE IF EXISTS objective_deadline_type;


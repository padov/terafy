-- migrate:up

-- Cria tipo ENUM para tipos de análise de IA
CREATE TYPE ai_analysis_type AS ENUM (
    'individual_session_analysis',
    'patient_overview',
    'evolution_analysis',
    'specific_situation',
    'treatment_plan_generation'
);

-- Cria tipo ENUM para status de análise de IA
CREATE TYPE ai_analysis_status AS ENUM ('pending', 'completed', 'failed');

-- Cria a tabela de análises de IA
CREATE TABLE ai_analyses (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    type ai_analysis_type NOT NULL,
    status ai_analysis_status NOT NULL DEFAULT 'pending',
    prompt TEXT NOT NULL,
    result TEXT,
    cost NUMERIC(10, 6) DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_cost_non_negative CHECK (cost >= 0)
);

-- Cria a tabela de ligação entre análises e sessões
CREATE TABLE ai_analysis_sessions (
    analysis_id INTEGER NOT NULL REFERENCES ai_analyses(id) ON DELETE CASCADE,
    session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (analysis_id, session_id)
);

-- Índices para performance
CREATE INDEX idx_ai_analyses_therapist_id ON ai_analyses(therapist_id);
CREATE INDEX idx_ai_analyses_patient_id ON ai_analyses(patient_id);
CREATE INDEX idx_ai_analyses_type ON ai_analyses(type);
CREATE INDEX idx_ai_analyses_status ON ai_analyses(status);
CREATE INDEX idx_ai_analyses_created_at ON ai_analyses(created_at);
CREATE INDEX idx_ai_analysis_sessions_session_id ON ai_analysis_sessions(session_id);

-- Habilita Row Level Security (RLS) na tabela ai_analyses
ALTER TABLE ai_analyses ENABLE ROW LEVEL SECURITY;

-- migrate:down

DROP INDEX IF EXISTS idx_ai_analysis_sessions_session_id;
DROP INDEX IF EXISTS idx_ai_analyses_created_at;
DROP INDEX IF EXISTS idx_ai_analyses_status;
DROP INDEX IF EXISTS idx_ai_analyses_type;
DROP INDEX IF EXISTS idx_ai_analyses_patient_id;
DROP INDEX IF EXISTS idx_ai_analyses_therapist_id;

DROP TABLE IF EXISTS ai_analysis_sessions;
DROP TABLE IF EXISTS ai_analyses;

DROP TYPE IF EXISTS ai_analysis_status;
DROP TYPE IF EXISTS ai_analysis_type;

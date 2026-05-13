-- migrate:up

-- Adiciona novas colunas para o modelo de Evolução de Sessão V2 (AI + Transcrição)
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS free_notes TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS transcription TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS session_report TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS progress_level TEXT;

-- migrate:down

ALTER TABLE sessions DROP COLUMN IF EXISTS progress_level;
ALTER TABLE sessions DROP COLUMN IF EXISTS session_report;
ALTER TABLE sessions DROP COLUMN IF EXISTS transcription;
ALTER TABLE sessions DROP COLUMN IF EXISTS free_notes;

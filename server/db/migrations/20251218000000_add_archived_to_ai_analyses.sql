-- migrate:up

ALTER TABLE ai_analyses 
ADD COLUMN archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Add index for filtering archived analyses
CREATE INDEX idx_ai_analyses_archived ON ai_analyses(archived);

-- Add index for common query pattern (patient_id + archived)
CREATE INDEX idx_ai_analyses_patient_archived ON ai_analyses(patient_id, archived);

-- migrate:down

DROP INDEX IF EXISTS idx_ai_analyses_patient_archived;
DROP INDEX IF EXISTS idx_ai_analyses_archived;

ALTER TABLE ai_analyses
DROP COLUMN IF EXISTS archived;

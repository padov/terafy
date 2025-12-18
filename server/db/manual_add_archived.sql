-- Script para adicionar coluna archived manualmente
-- Execute este script diretamente no PostgreSQL

-- Verificar se a coluna já existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'ai_analyses' 
        AND column_name = 'archived'
    ) THEN
        -- Adicionar coluna archived
        ALTER TABLE ai_analyses 
        ADD COLUMN archived BOOLEAN NOT NULL DEFAULT FALSE;
        
        -- Criar índices
        CREATE INDEX idx_ai_analyses_archived ON ai_analyses(archived);
        CREATE INDEX idx_ai_analyses_patient_archived ON ai_analyses(patient_id, archived);
        
        RAISE NOTICE 'Coluna archived adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna archived já existe!';
    END IF;
END $$;

-- Verificar se foi criada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'ai_analyses' AND column_name = 'archived';

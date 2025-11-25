-- migrate:up

-- Remove a coluna behavioral_profiles da tabela patients
ALTER TABLE patients DROP COLUMN IF EXISTS behavioral_profiles;

-- migrate:down

-- Restaura a coluna behavioral_profiles (caso seja necessário reverter)
ALTER TABLE patients ADD COLUMN behavioral_profiles TEXT[] DEFAULT ARRAY[]::TEXT[];


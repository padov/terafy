-- migrate:up

-- Adiciona coluna user_id na tabela therapists
ALTER TABLE therapists 
ADD COLUMN user_id INTEGER REFERENCES users(id) UNIQUE;

-- Índice para performance
CREATE INDEX idx_therapists_user_id ON therapists(user_id);

-- migrate:down

-- Remove a coluna user_id da tabela therapists
DROP INDEX IF EXISTS idx_therapists_user_id;
ALTER TABLE therapists DROP COLUMN IF EXISTS user_id;


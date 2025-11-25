-- migrate:up

-- Adiciona coluna nickname na tabela therapists
ALTER TABLE therapists 
ADD COLUMN nickname VARCHAR(100);

-- migrate:down

-- Remove a coluna nickname da tabela therapists
ALTER TABLE therapists DROP COLUMN IF EXISTS nickname;


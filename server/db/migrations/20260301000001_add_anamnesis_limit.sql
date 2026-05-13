-- migrate:up

ALTER TABLE plans ADD COLUMN custom_anamnesis_limit INT NOT NULL DEFAULT 0;

-- Atualizar planos existentes
UPDATE plans SET custom_anamnesis_limit = 0 WHERE name ILIKE '%free%';
UPDATE plans SET custom_anamnesis_limit = 2 WHERE name ILIKE '%starter%';

-- migrate:down

ALTER TABLE plans DROP COLUMN custom_anamnesis_limit;

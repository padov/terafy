-- migrate:up

ALTER TABLE therapists
ADD COLUMN experience_time TEXT NULL;

ALTER TABLE therapists
ADD COLUMN ai_config JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN therapists.experience_time IS 'Tempo de experiência do terapeuta (ex: "10 anos")';
COMMENT ON COLUMN therapists.ai_config IS 'Configurações personalizadas para a IA do terapeuta (perfil, tom, preferências)';

-- migrate:down

ALTER TABLE therapists
DROP COLUMN IF EXISTS experience_time;

ALTER TABLE therapists
DROP COLUMN IF EXISTS ai_config;

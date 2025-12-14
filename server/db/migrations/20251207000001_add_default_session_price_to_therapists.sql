-- migrate:up

-- Adicionar coluna default_session_price na tabela therapists
ALTER TABLE therapists
ADD COLUMN default_session_price DECIMAL(10,2) NULL;

COMMENT ON COLUMN therapists.default_session_price IS 
'Preço padrão cobrado por sessão. Usado quando charged_amount não é especificado na criação da sessão.';

-- migrate:down

-- Remover coluna default_session_price
ALTER TABLE therapists
DROP COLUMN IF EXISTS default_session_price;

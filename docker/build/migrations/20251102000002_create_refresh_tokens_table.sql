-- migrate:up

-- Cria tabela para armazenar refresh tokens
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    device_info TEXT, -- Informações do dispositivo (opcional)
    ip_address VARCHAR(45), -- IPv4 ou IPv6
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_used_at  TIMESTAMP WITH TIME ZONE,
    
    -- Índices para performance
    CONSTRAINT check_expires_at CHECK (expires_at > created_at)
);

-- Índices para performance
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_revoked ON refresh_tokens(revoked);

-- Índice composto para queries comuns
CREATE INDEX idx_refresh_tokens_user_revoked ON refresh_tokens(user_id, revoked);

-- migrate:down

-- Remove a tabela de refresh tokens
DROP TABLE IF EXISTS refresh_tokens;


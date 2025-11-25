-- migrate:up

-- Cria tabela para blacklist de tokens (access tokens revogados)
-- Esta tabela armazena tokens que foram revogados antes de expirar
CREATE TABLE token_blacklist (
    token_id VARCHAR(255) PRIMARY KEY, -- JTI (JWT ID) ou hash do token
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL, -- Quando o token originalmente expiraria
    revoked_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    reason VARCHAR(100), -- Motivo da revogação: 'logout', 'security', 'password_change', etc.
    
    -- Índice para limpeza automática de tokens expirados
    CONSTRAINT check_expires_at CHECK (expires_at > revoked_at)
);

-- Índices para performance
CREATE INDEX idx_token_blacklist_user_id ON token_blacklist(user_id);
-- Índice para limpeza de tokens expirados (sem WHERE porque NOW() não é IMMUTABLE)
CREATE INDEX idx_token_blacklist_expires_at ON token_blacklist(expires_at);

-- migrate:down

-- Remove a tabela de blacklist
DROP TABLE IF EXISTS token_blacklist;


-- migrate:up

-- Cria tipo ENUM para roles de usuário
CREATE TYPE user_role AS ENUM ('therapist', 'patient', 'admin');

-- Cria tipos ENUM para garantir a integridade dos dados em campos específicos
CREATE TYPE account_status AS ENUM ('active', 'suspended', 'canceled');

-- Cria tipo ENUM para tipos de conta
CREATE TYPE account_type AS ENUM ('therapist', 'patient');

-- Cria tipo ENUM para métodos de TFA
CREATE TYPE tfa_method AS ENUM ('authenticator_app', 'sms', 'email');

-- Cria a tabela de usuários para autenticação centralizada
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role user_role NOT NULL DEFAULT 'therapist',
    account_type account_type,
    account_id INTEGER, -- FK para therapists ou patients (polimórfico)
    status account_status NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    -- Campos de TFA (Two-Factor Authentication)
    tfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    tfa_secret VARCHAR(255), -- Secret para TOTP (geralmente 32 caracteres base32)
    tfa_method tfa_method, -- Método de TFA preferido
    tfa_backup_codes TEXT, -- Códigos de backup (JSON array ou texto separado por vírgula)
    tfa_verified_at  TIMESTAMP WITH TIME ZONE, -- Data em que o TFA foi verificado/ativado
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraint: se account_type está definido, account_id também deve estar
    CONSTRAINT check_account_fields CHECK (
        (account_type IS NULL AND account_id IS NULL) OR
        (account_type IS NOT NULL AND account_id IS NOT NULL)
    ),
    
    -- Constraint: se tfa_enabled é TRUE, tfa_secret e tfa_method devem estar definidos
    CONSTRAINT check_tfa_fields CHECK (
        (tfa_enabled = FALSE) OR
        (tfa_enabled = TRUE AND tfa_secret IS NOT NULL AND tfa_method IS NOT NULL)
    )
);

-- Índices para performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_account ON users(account_type, account_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_tfa_enabled ON users(tfa_enabled) WHERE tfa_enabled = TRUE;

-- migrate:down

-- Remove a tabela de usuários e tipos enum
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS user_role;
DROP TYPE IF EXISTS account_type;
DROP TYPE IF EXISTS tfa_method;


-- migrate:up

-- Tipos auxiliares para mensagens
CREATE TYPE message_type AS ENUM (
  'appointmentReminder',
  'appointmentConfirmation',
  'appointmentCancellation',
  'sessionReminder',
  'general',
  'notification'
);

CREATE TYPE message_channel AS ENUM ('email', 'sms', 'whatsapp', 'push');

CREATE TYPE message_status AS ENUM (
  'pending',
  'scheduled',
  'sent',
  'delivered',
  'failed',
  'cancelled'
);

CREATE TYPE message_priority AS ENUM ('low', 'normal', 'high', 'urgent');

CREATE TYPE recipient_type AS ENUM ('therapist', 'patient');

-- Tabela de templates de mensagens
CREATE TABLE message_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type message_type NOT NULL,
    channel message_channel NOT NULL,
    subject_template TEXT NOT NULL,
    content_template TEXT NOT NULL,
    variables JSONB DEFAULT '[]'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_template_type_channel UNIQUE (type, channel)
);

-- Tabela de mensagens
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    message_type message_type NOT NULL,
    channel message_channel NOT NULL,
    recipient_type recipient_type NOT NULL,
    recipient_id INTEGER NOT NULL,
    sender_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    subject VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    template_id INTEGER REFERENCES message_templates(id) ON DELETE SET NULL,
    status message_status NOT NULL DEFAULT 'pending',
    priority message_priority NOT NULL DEFAULT 'normal',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    metadata JSONB,
    related_entity_type VARCHAR(50),
    related_entity_id INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela de fila de mensagens (para agendamento e retry)
CREATE TABLE message_queue (
    id SERIAL PRIMARY KEY,
    message_id INTEGER NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER NOT NULL DEFAULT 3,
    last_attempt_at TIMESTAMP WITH TIME ZONE,
    next_attempt_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_messages_recipient ON messages(recipient_type, recipient_id);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_channel ON messages(channel);
CREATE INDEX idx_messages_scheduled ON messages(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_messages_related_entity ON messages(related_entity_type, related_entity_id) WHERE related_entity_type IS NOT NULL;
CREATE INDEX idx_messages_created_at ON messages(created_at);

CREATE INDEX idx_message_queue_scheduled ON message_queue(scheduled_at, status) WHERE status = 'pending';
CREATE INDEX idx_message_queue_message_id ON message_queue(message_id);
CREATE INDEX idx_message_queue_next_attempt ON message_queue(next_attempt_at, status) WHERE status IN ('pending', 'processing');

CREATE INDEX idx_message_templates_type_channel ON message_templates(type, channel) WHERE is_active = TRUE;

-- migrate:down

DROP INDEX IF EXISTS idx_message_templates_type_channel;
DROP INDEX IF EXISTS idx_message_queue_next_attempt;
DROP INDEX IF EXISTS idx_message_queue_message_id;
DROP INDEX IF EXISTS idx_message_queue_scheduled;
DROP INDEX IF EXISTS idx_messages_created_at;
DROP INDEX IF EXISTS idx_messages_related_entity;
DROP INDEX IF EXISTS idx_messages_scheduled;
DROP INDEX IF EXISTS idx_messages_channel;
DROP INDEX IF EXISTS idx_messages_status;
DROP INDEX IF EXISTS idx_messages_recipient;

DROP TABLE IF EXISTS message_queue;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS message_templates;

DROP TYPE IF EXISTS recipient_type;
DROP TYPE IF EXISTS message_priority;
DROP TYPE IF EXISTS message_status;
DROP TYPE IF EXISTS message_channel;
DROP TYPE IF EXISTS message_type;


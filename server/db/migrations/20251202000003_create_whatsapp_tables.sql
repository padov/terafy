-- migrate:up

-- Tabela de instâncias WhatsApp (Evolution API)
CREATE TABLE whatsapp_instances (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL UNIQUE REFERENCES therapists(id) ON DELETE CASCADE,
    instance_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'disconnected', -- connected, disconnected, connecting
    webhook_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela de conversas WhatsApp
CREATE TABLE whatsapp_conversations (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    patient_id INTEGER REFERENCES patients(id) ON DELETE SET NULL,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    current_state VARCHAR(50) NOT NULL DEFAULT 'idle', -- idle, identifying, menu, scheduling_date, scheduling_time, confirming, viewing_appointments, canceling
    context_data JSONB DEFAULT '{}'::JSONB, -- Dados temporários da conversa
    last_interaction_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_conversation_phone_therapist UNIQUE (phone_number, therapist_id)
);

-- Tabela de mensagens WhatsApp (histórico detalhado)
CREATE TABLE whatsapp_messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES whatsapp_conversations(id) ON DELETE CASCADE,
    direction VARCHAR(10) NOT NULL, -- inbound, outbound
    message_type VARCHAR(20) NOT NULL, -- text, button, list, media
    content TEXT,
    metadata JSONB,
    external_message_id VARCHAR(255), -- ID da mensagem no Evolution API
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Adicionar configurações WhatsApp em therapist_schedule_settings
ALTER TABLE therapist_schedule_settings
ADD COLUMN whatsapp_phone_number VARCHAR(20),
ADD COLUMN whatsapp_reminder_days INTEGER NOT NULL DEFAULT 1,
ADD COLUMN whatsapp_enabled BOOLEAN NOT NULL DEFAULT FALSE;

-- Índices
CREATE INDEX idx_whatsapp_instances_therapist ON whatsapp_instances(therapist_id);
CREATE INDEX idx_whatsapp_instances_status ON whatsapp_instances(status);
CREATE INDEX idx_whatsapp_conversations_phone ON whatsapp_conversations(phone_number);
CREATE INDEX idx_whatsapp_conversations_patient ON whatsapp_conversations(patient_id);
CREATE INDEX idx_whatsapp_conversations_therapist ON whatsapp_conversations(therapist_id);
CREATE INDEX idx_whatsapp_conversations_state ON whatsapp_conversations(current_state);
CREATE INDEX idx_whatsapp_messages_conversation ON whatsapp_messages(conversation_id);
CREATE INDEX idx_whatsapp_messages_external_id ON whatsapp_messages(external_message_id);
CREATE INDEX idx_whatsapp_messages_sent_at ON whatsapp_messages(sent_at);

-- migrate:down

DROP INDEX IF EXISTS idx_whatsapp_messages_sent_at;
DROP INDEX IF EXISTS idx_whatsapp_messages_external_id;
DROP INDEX IF EXISTS idx_whatsapp_messages_conversation;
DROP INDEX IF EXISTS idx_whatsapp_conversations_state;
DROP INDEX IF EXISTS idx_whatsapp_conversations_therapist;
DROP INDEX IF EXISTS idx_whatsapp_conversations_patient;
DROP INDEX IF EXISTS idx_whatsapp_conversations_phone;
DROP INDEX IF EXISTS idx_whatsapp_instances_status;
DROP INDEX IF EXISTS idx_whatsapp_instances_therapist;

ALTER TABLE therapist_schedule_settings
DROP COLUMN IF EXISTS whatsapp_enabled,
DROP COLUMN IF EXISTS whatsapp_reminder_days,
DROP COLUMN IF EXISTS whatsapp_phone_number;

DROP TABLE IF EXISTS whatsapp_messages;
DROP TABLE IF EXISTS whatsapp_conversations;
DROP TABLE IF EXISTS whatsapp_instances;


-- migrate:up

-- Adiciona campos para integração com Google Play Billing
ALTER TABLE plans
  ADD COLUMN IF NOT EXISTS play_store_product_id VARCHAR(255),
  ADD COLUMN IF NOT EXISTS billing_period VARCHAR(20) DEFAULT 'monthly' CHECK (billing_period IN ('monthly', 'annual'));

-- Cria índice para busca rápida por product_id
CREATE INDEX IF NOT EXISTS idx_plans_play_store_product_id ON plans(play_store_product_id);

-- Insere planos padrão (Free e Starter)
INSERT INTO plans (name, description, price, patient_limit, features, play_store_product_id, billing_period, is_active)
VALUES 
  (
    'Free',
    'Plano gratuito com funcionalidades básicas',
    0.00,
    10,
    ARRAY[
        'Até 10 pacientes', 
        'Anamnese Básica (template padrão)', 
        'Agenda básica', 
        'Perfil comportamental simplificado',
        'Registro de Sessões'
    ],
    NULL, -- Plano gratuito não tem product_id
    'monthly',
    TRUE
  ),
  (
    'Starter',
    'Plano Starter com limite ampliado de pacientes',
    30.00,
    999999, -- Praticamente ilimitado (999.999 pacientes)
    ARRAY[
        'Pacientes ilimitados', 
        'Até 2 templates de Anamnese customizáveis',
        'Registro de sessões',
        'Plano terapêutico estruturado',
        'Perfil comportamental completo',
        'Agenda avançada com recorrência',
        'Lembretes automáticos (email/SMS)',
        'Controle financeiro',
        'IA (sob demanda)'
    ],
    'starter_monthly', -- Será configurado no Play Console
    'monthly',
    TRUE
  ),
  (
    'Full',
    'Plano Full com todas as funcionalidades',
    60.00,
    999999, -- Praticamente ilimitado (999.999 pacientes)
    ARRAY[
        'Todos do plano Starter +', 
        'Integração com Google Calendar',
        'Plano terapêutico customizável',
        'Anamnese completa customizável',
        'Integração com Whatsapp',
        'Webhooks e API access',
        'IA (até 60 consultas, sob demanda)',
      ],
    'starter_monthly', -- Será configurado no Play Console
    'monthly',
    TRUE
  )
ON CONFLICT (name) DO NOTHING;

-- migrate:down

-- Remove os campos adicionados
ALTER TABLE plans
  DROP COLUMN IF EXISTS play_store_product_id,
  DROP COLUMN IF EXISTS billing_period;

DROP INDEX IF EXISTS idx_plans_play_store_product_id;


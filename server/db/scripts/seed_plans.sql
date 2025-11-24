-- Script para popular a tabela de planos com planos iniciais
-- Execute este script após executar as migrations

-- Remove subscriptions existentes primeiro (devido à FK)
DELETE FROM plan_subscriptions;
-- Remove planos existentes (para reexecutar o script)
DELETE FROM plans;
-- Reseta a sequence para garantir IDs consistentes (1, 2, 3)
ALTER SEQUENCE plans_id_seq RESTART WITH 1;

-- Insere planos básicos
INSERT INTO plans (name, description, price, patient_limit, features, is_active) VALUES
  (
    'Básico',
    'Plano ideal para começar sua prática terapêutica',
    99.90,
    20,
    ARRAY['Até 20 pacientes', 'Agenda completa', 'Registro de sessões', 'Relatórios básicos'],
    true
  ),
  (
    'Profissional',
    'Plano completo para terapeutas estabelecidos',
    199.90,
    50,
    ARRAY['Até 50 pacientes', 'Agenda completa', 'Registro de sessões', 'Relatórios avançados', 'Integração com pagamentos'],
    true
  ),
  (
    'Premium',
    'Plano máximo com todos os recursos disponíveis',
    299.90,
    999,
    ARRAY['Pacientes ilimitados', 'Agenda completa', 'Registro de sessões', 'Relatórios avançados', 'Integração com pagamentos', 'Suporte prioritário', 'Personalização avançada'],
    true
  );

-- Verificar planos criados
SELECT id, name, price, patient_limit, is_active 
FROM plans 
ORDER BY price;

-- Policy para controlar acesso às assinaturas de planos
-- - therapist: acessa apenas suas próprias assinaturas (therapist_id)
-- - admin: acessa todas as assinaturas (sem validação)

-- Habilita Row Level Security (RLS) na tabela plan_subscriptions
ALTER TABLE plan_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS plan_subscriptions_policy ON plan_subscriptions;

CREATE POLICY plan_subscriptions_policy ON plan_subscriptions
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas suas próprias assinaturas
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas suas próprias assinaturas
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  );


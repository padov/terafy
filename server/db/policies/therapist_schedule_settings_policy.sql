-- Policy para controlar acesso às configurações de agenda
-- - therapist: acessa apenas suas próprias configurações (therapist_id)
-- - admin: acessa todas as configurações (sem validação)

-- Habilita Row Level Security (RLS) na tabela therapist_schedule_settings
ALTER TABLE therapist_schedule_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS therapist_schedule_settings_policy ON therapist_schedule_settings;

CREATE POLICY therapist_schedule_settings_policy ON therapist_schedule_settings
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas suas próprias configurações
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas suas próprias configurações
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  );


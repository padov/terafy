-- Policy para controlar acesso às sessões
-- - therapist: acessa apenas suas próprias sessões (therapist_id)
-- - patient: acessa apenas suas próprias sessões (patient_id vinculado ao user_id)
-- - admin: acessa todas as sessões (sem validação)

-- Habilita Row Level Security (RLS) na tabela sessions
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sessions_policy ON sessions;

CREATE POLICY sessions_policy ON sessions
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas suas próprias sessões
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient acessa apenas suas próprias sessões
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas suas próprias sessões
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient pode criar/atualizar apenas suas próprias sessões
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  );


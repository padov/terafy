-- Policy para controlar acesso aos agendamentos
-- - therapist: acessa apenas seus próprios agendamentos (therapist_id)
-- - patient: acessa apenas seus próprios agendamentos (patient_id vinculado ao user_id)
-- - admin: acessa todos os agendamentos (sem validação)

-- Habilita Row Level Security (RLS) na tabela appointments
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS appointments_policy ON appointments;

CREATE POLICY appointments_policy ON appointments
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas seus próprios agendamentos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient acessa apenas seus próprios agendamentos
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas seus próprios agendamentos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient pode criar/atualizar apenas seus próprios agendamentos
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  );


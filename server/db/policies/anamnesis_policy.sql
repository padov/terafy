-- Policy para controlar acesso às anamneses
-- - therapist: acessa apenas suas próprias anamneses (therapist_id)
-- - patient: acessa apenas suas próprias anamneses (patient_id vinculado ao user_id)
-- - admin: acessa todas as anamneses (sem validação)

-- Habilita Row Level Security (RLS) na tabela anamnesis
ALTER TABLE anamnesis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anamnesis_policy ON anamnesis;

CREATE POLICY anamnesis_policy ON anamnesis
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas suas próprias anamneses
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient acessa apenas suas próprias anamneses
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas suas próprias anamneses
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient pode criar/atualizar apenas suas próprias anamneses
    (current_setting('app.user_role', true) = 'patient' 
     AND patient_id = current_setting('app.account_id', true)::int)
  );


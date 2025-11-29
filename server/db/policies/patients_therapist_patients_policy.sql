-- Policy para controlar acesso aos pacientes baseado na role do usuário
-- - therapist: acessa apenas pacientes vinculados ao seu therapist_id (account_id)
-- - patient: acessa apenas seus próprios dados (user_id)
-- - admin: acessa todos os pacientes (sem validação)
DROP POLICY IF EXISTS therapist_patients_policy ON patients;

CREATE POLICY therapist_patients_policy ON patients
  FOR ALL
  USING (
    -- Admin acessa tudo (não valida nada)
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa pacientes vinculados ao seu account_id
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient acessa apenas seus próprios dados
    (current_setting('app.user_role', true) = 'patient' 
     AND user_id = current_setting('app.user_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas seus pacientes
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
    OR
    -- Patient pode modificar apenas seus próprios dados
    (current_setting('app.user_role', true) = 'patient' 
     AND user_id = current_setting('app.user_id', true)::int)
  );


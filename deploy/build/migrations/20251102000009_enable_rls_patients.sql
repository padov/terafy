-- migrate:up

-- Habilita Row Level Security (RLS) na tabela patients
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Policy para terapeutas acessarem apenas pacientes vinculados ao seu account_id
CREATE POLICY therapist_patients_policy ON patients
  FOR ALL
  USING (
    therapist_id = current_setting('app.account_id', true)::int
    OR user_id = current_setting('app.user_id', true)::int
  )
  WITH CHECK (
    therapist_id = current_setting('app.account_id', true)::int
    OR current_setting('app.user_role', true) = 'admin'
  );

-- Policy específica para admins acessarem todos os pacientes
CREATE POLICY admin_patients_policy ON patients
  FOR ALL
  USING (current_setting('app.user_role', true) = 'admin')
  WITH CHECK (current_setting('app.user_role', true) = 'admin');

-- Policy que permite criação de pacientes por terapeutas vinculados
CREATE POLICY therapist_patients_insert_policy ON patients
  FOR INSERT
  WITH CHECK (
    therapist_id = current_setting('app.account_id', true)::int
    OR current_setting('app.user_role', true) = 'admin'
  );

-- migrate:down

DROP POLICY IF EXISTS therapist_patients_insert_policy ON patients;
DROP POLICY IF EXISTS admin_patients_policy ON patients;
DROP POLICY IF EXISTS therapist_patients_policy ON patients;
ALTER TABLE patients DISABLE ROW LEVEL SECURITY;


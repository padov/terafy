-- Policy para controlar acesso aos terapeutas baseado na role do usuário
-- - therapist: acessa apenas seus próprios dados (user_id)
-- - admin: acessa todos os terapeutas (sem validação)
-- - patient: não acessa terapeutas (política não permite)
DROP POLICY IF EXISTS therapist_policy ON therapists;

CREATE POLICY therapist_policy ON therapists
  FOR ALL
  USING (
    -- Admin acessa tudo (não valida nada)
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas seus próprios dados
    (current_setting('app.user_role', true) = 'therapist' 
     AND user_id = current_setting('app.user_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas seus próprios dados
    (current_setting('app.user_role', true) = 'therapist' 
     AND user_id = current_setting('app.user_id', true)::int)
    OR
    -- Permite criar therapist sem user_id (criação inicial, será vinculado depois)
    (current_setting('app.user_role', true) = 'therapist' 
     AND user_id IS NULL)
  );


-- migrate:up

-- Policy para controlar acesso aos planos terapêuticos
-- - therapist: acessa apenas seus próprios planos (therapist_id)
-- - admin: acessa todos os planos (sem validação)

DROP POLICY IF EXISTS therapeutic_plans_policy ON therapeutic_plans;

CREATE POLICY therapeutic_plans_policy ON therapeutic_plans
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas seus próprios planos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas seus próprios planos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  );

-- Policy para controlar acesso aos objetivos terapêuticos
-- - therapist: acessa apenas seus próprios objetivos (therapist_id)
-- - admin: acessa todos os objetivos (sem validação)

DROP POLICY IF EXISTS therapeutic_objectives_policy ON therapeutic_objectives;

CREATE POLICY therapeutic_objectives_policy ON therapeutic_objectives
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas seus próprios objetivos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas seus próprios objetivos
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  );

-- Policy para controlar acesso às reavaliações de planos
-- - therapist: acessa apenas suas próprias reavaliações (therapist_id)
-- - admin: acessa todas as reavaliações (sem validação)

DROP POLICY IF EXISTS therapeutic_plan_reassessments_policy ON therapeutic_plan_reassessments;

CREATE POLICY therapeutic_plan_reassessments_policy ON therapeutic_plan_reassessments
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa apenas suas próprias reavaliações
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode modificar apenas suas próprias reavaliações
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int)
  );

-- migrate:down

DROP POLICY IF EXISTS therapeutic_plan_reassessments_policy ON therapeutic_plan_reassessments;
DROP POLICY IF EXISTS therapeutic_objectives_policy ON therapeutic_objectives;
DROP POLICY IF EXISTS therapeutic_plans_policy ON therapeutic_plans;


-- Policy para controlar acesso aos templates de anamnese
-- - therapist: acessa seus próprios templates ou templates do sistema (is_system = true)
-- - admin: acessa todos os templates (sem validação)

-- Habilita Row Level Security (RLS) na tabela anamnesis_templates
ALTER TABLE anamnesis_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anamnesis_templates_policy ON anamnesis_templates;

CREATE POLICY anamnesis_templates_policy ON anamnesis_templates
  FOR ALL
  USING (
    -- Admin acessa tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist acessa seus próprios templates ou templates do sistema
    (current_setting('app.user_role', true) = 'therapist' 
     AND (
       therapist_id = current_setting('app.account_id', true)::int
       OR is_system = TRUE
     ))
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
    OR
    -- Therapist pode criar/modificar apenas seus próprios templates (não pode modificar templates do sistema)
    (current_setting('app.user_role', true) = 'therapist' 
     AND therapist_id = current_setting('app.account_id', true)::int
     AND (is_system IS NULL OR is_system = FALSE))
  );


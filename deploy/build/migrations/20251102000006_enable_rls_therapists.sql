-- migrate:up

-- Habilita Row Level Security (RLS) na tabela therapists
ALTER TABLE therapists ENABLE ROW LEVEL SECURITY;

-- Policy para therapists: podem ver e modificar apenas seus próprios dados
-- Usa a variável de sessão 'app.user_id' definida pelo código Dart
CREATE POLICY therapist_own_data_policy ON therapists
  FOR ALL
  USING (
    -- Permite acesso se o user_id do therapist corresponde ao user_id da sessão
    user_id = current_setting('app.user_id', true)::int
  )
  WITH CHECK (
    -- Garante que só pode inserir/atualizar seus próprios dados
    user_id = current_setting('app.user_id', true)::int
  );

-- Policy para admins: podem ver e modificar todos os dados
-- Usa a variável de sessão 'app.user_role' definida pelo código Dart
CREATE POLICY admin_all_data_policy ON therapists
  FOR ALL
  USING (
    -- Admin pode acessar tudo
    current_setting('app.user_role', true) = 'admin'
  )
  WITH CHECK (
    -- Admin pode modificar tudo
    current_setting('app.user_role', true) = 'admin'
  );

-- Policy para criação inicial: permite criar therapist sem user_id
-- (será vinculado depois via updateTherapistUserId)
CREATE POLICY therapist_create_policy ON therapists
  FOR INSERT
  WITH CHECK (
    -- Permite criar se não tem user_id ainda (criação inicial)
    user_id IS NULL
    OR
    -- Ou se o user_id corresponde ao da sessão
    user_id = current_setting('app.user_id', true)::int
    OR
    -- Ou se é admin
    current_setting('app.user_role', true) = 'admin'
  );

-- migrate:down

-- Remove as policies
DROP POLICY IF EXISTS therapist_own_data_policy ON therapists;
DROP POLICY IF EXISTS admin_all_data_policy ON therapists;
DROP POLICY IF EXISTS therapist_create_policy ON therapists;

-- Desabilita RLS
ALTER TABLE therapists DISABLE ROW LEVEL SECURITY;


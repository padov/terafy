-- Function: ft_session_b_u_update_updated_at
-- Trigger: trg_session_b_u_update_updated_at
-- Descrição: Atualiza automaticamente o campo updated_at da tabela sessions
-- Tabela: sessions
-- Timing: BEFORE UPDATE
--
-- Comportamento:
-- - Define updated_at para o timestamp atual sempre que um registro é atualizado

CREATE OR REPLACE FUNCTION ft_session_b_u_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_session_b_u_update_updated_at ON sessions;

CREATE TRIGGER trg_session_b_u_update_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION ft_session_b_u_update_updated_at();

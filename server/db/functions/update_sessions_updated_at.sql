-- Function: update_sessions_updated_at
-- Descrição: Atualiza automaticamente o campo updated_at da tabela sessions
--
-- Quando usar: Trigger BEFORE UPDATE na tabela sessions

CREATE OR REPLACE FUNCTION update_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


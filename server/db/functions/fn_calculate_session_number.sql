-- Function: fn_calculate_session_number
-- Trigger: trg_session_bi_calculate_session_number
-- Descrição: Calcula automaticamente o número da sessão (sequencial por paciente)
-- Tabela: sessions
-- Timing: BEFORE INSERT
--
-- Comportamento:
-- - Se session_number é NULL ou 0, calcula o próximo número sequencial para o paciente
-- - Busca o maior session_number existente para o paciente e adiciona 1
-- - Se não houver sessões anteriores, começa com 1

CREATE OR REPLACE FUNCTION fn_calculate_session_number()
RETURNS TRIGGER AS $$
BEGIN
  -- Se session_number não foi fornecido ou é 0, calcular automaticamente
  IF NEW.session_number IS NULL OR NEW.session_number = 0 THEN
    SELECT COALESCE(MAX(session_number), 0) + 1
    INTO NEW.session_number
    FROM sessions
    WHERE patient_id = NEW.patient_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_session_bi_calculate_session_number ON sessions;

CREATE TRIGGER trg_session_bi_calculate_session_number
BEFORE INSERT ON sessions
FOR EACH ROW
EXECUTE FUNCTION fn_calculate_session_number();

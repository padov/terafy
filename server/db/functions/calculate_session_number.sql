-- Function: calculate_session_number
-- Descrição: Calcula automaticamente o número da sessão (sequencial por paciente)
-- Se session_number não foi fornecido ou é 0, calcula automaticamente
--
-- Quando usar: Trigger BEFORE INSERT na tabela sessions

CREATE OR REPLACE FUNCTION calculate_session_number()
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


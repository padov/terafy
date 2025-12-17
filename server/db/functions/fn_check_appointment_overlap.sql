-- Function: fn_check_appointment_overlap
-- Trigger: trg_appointment_bi_check_overlap, trg_appointment_bu_check_overlap
-- Descrição: Verifica se há agendamentos sobrepostos para o mesmo terapeuta
-- Tabela: appointments
-- Timing: BEFORE INSERT, BEFORE UPDATE
--
-- Comportamento:
-- - Verifica se há conflito de horário para o mesmo terapeuta
-- - Dois intervalos se sobrepõem se: start_time < outro.end_time AND end_time > outro.start_time
-- - Exclui agendamentos cancelados da verificação
-- - Exclui o próprio registro (no caso de UPDATE)
-- - Lança exceção se houver sobreposição

CREATE OR REPLACE FUNCTION fn_check_appointment_overlap()
RETURNS TRIGGER 
SECURITY DEFINER  -- Executa com privilégios do dono da função para contornar RLS
AS $$
DECLARE
  v_overlapping_count INTEGER;
BEGIN
  -- Verifica se há agendamentos sobrepostos para o mesmo terapeuta
  -- SECURITY DEFINER permite que a função veja todos os agendamentos, mesmo com RLS ativo
  SELECT COUNT(*)
  INTO v_overlapping_count
  FROM appointments
  WHERE therapist_id = NEW.therapist_id
    AND id != COALESCE(NEW.id, 0)  -- Exclui o próprio registro no UPDATE
    AND status != 'cancelled'       -- Ignora agendamentos cancelados
    AND start_time < NEW.end_time
    AND end_time > NEW.start_time;
  
  IF v_overlapping_count > 0 THEN
    RAISE EXCEPTION 'Conflito de horário: já existe um agendamento para este terapeuta no período de % a %', 
      NEW.start_time, NEW.end_time;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar triggers
DROP TRIGGER IF EXISTS trg_appointment_bi_check_overlap ON appointments;
DROP TRIGGER IF EXISTS trg_appointment_bu_check_overlap ON appointments;

CREATE TRIGGER trg_appointment_bi_check_overlap
BEFORE INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION fn_check_appointment_overlap();

CREATE TRIGGER trg_appointment_bu_check_overlap
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (
  -- Só executa se o horário ou o terapeuta mudaram
  OLD.start_time IS DISTINCT FROM NEW.start_time
  OR OLD.end_time IS DISTINCT FROM NEW.end_time
  OR OLD.therapist_id IS DISTINCT FROM NEW.therapist_id
  OR OLD.status IS DISTINCT FROM NEW.status
)
EXECUTE FUNCTION fn_check_appointment_overlap();

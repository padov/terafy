-- Function: ft_appointment_a_u_sync_patient_stats
-- Trigger: trg_appointment_a_u_sync_patient_stats
-- Descrição: Atualiza total_sessions e last_session_date em patients
-- quando o status de um appointment é alterado para 'completed' ou de 'completed' para outro status
-- Tabela: appointments
-- Timing: AFTER UPDATE OF status
--
-- Comportamento:
-- - Quando status muda para 'completed': incrementa total_sessions e atualiza last_session_date
-- - Quando status muda de 'completed' para outro: recalcula total_sessions e last_session_date

CREATE OR REPLACE FUNCTION ft_appointment_a_u_sync_patient_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_total_sessions INTEGER;
  v_last_session_date DATE;
BEGIN
  -- Se o status foi alterado para completado e era não completado, incrementa o total de sessões e atualiza a data da última sessão
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE patients
    SET total_sessions = total_sessions + 1
      , last_session_date = NEW.start_time
    WHERE id = NEW.patient_id;
  END IF;

  -- Se o status foi alterado para não completado e era completado, recalcula o total de sessões e a data da última sessão
  IF NEW.status != 'completed' AND OLD.status = 'completed' THEN
    SELECT 
      COUNT(*)
      , MAX(start_time) AS last_session_date
    INTO 
      v_total_sessions
      , v_last_session_date
    FROM 
      appointments
    WHERE 
      patient_id = NEW.patient_id
      AND type = 'session'::appointment_type
      AND status = 'completed'::appointment_status;
    
    UPDATE 
      patients
    SET 
      total_sessions = v_total_sessions
      , last_session_date = v_last_session_date
    WHERE 
      id = NEW.patient_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_appointment_a_u_sync_patient_stats ON appointments;

CREATE TRIGGER trg_appointment_a_u_sync_patient_stats
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_appointment_a_u_sync_patient_stats();

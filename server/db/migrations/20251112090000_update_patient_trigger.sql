-- migrate:up
CREATE OR REPLACE FUNCTION ft_after_appointment()
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

DROP TRIGGER IF EXISTS trigger_update_patient_total_sessions ON appointments;

CREATE TRIGGER t_after_appointment
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_after_appointment();

-- migrate:down
DROP TRIGGER IF EXISTS t_after_appointment ON appointments;
DROP FUNCTION IF EXISTS ft_after_appointment();


-- migrate:up

-- Função para verificar sobreposição de agendamentos
CREATE OR REPLACE FUNCTION check_appointment_overlap()
RETURNS TRIGGER AS $$
DECLARE
  v_overlapping_count INTEGER;
BEGIN
  -- Verifica se há agendamentos sobrepostos para o mesmo terapeuta
  -- Dois intervalos se sobrepõem se: start_time < outro.end_time AND end_time > outro.start_time
  -- Exclui agendamentos cancelados e o próprio registro (no caso de UPDATE)
  
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

-- Trigger BEFORE INSERT para verificar sobreposição na criação
CREATE TRIGGER t_prevent_appointment_overlap_insert
BEFORE INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION check_appointment_overlap();

-- Trigger BEFORE UPDATE para verificar sobreposição na atualização
CREATE TRIGGER t_prevent_appointment_overlap_update
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (
  -- Só executa se o horário ou o terapeuta mudaram
  OLD.start_time IS DISTINCT FROM NEW.start_time
  OR OLD.end_time IS DISTINCT FROM NEW.end_time
  OR OLD.therapist_id IS DISTINCT FROM NEW.therapist_id
  OR OLD.status IS DISTINCT FROM NEW.status
)
EXECUTE FUNCTION check_appointment_overlap();

-- migrate:down

DROP TRIGGER IF EXISTS t_prevent_appointment_overlap_update ON appointments;
DROP TRIGGER IF EXISTS t_prevent_appointment_overlap_insert ON appointments;
DROP FUNCTION IF EXISTS check_appointment_overlap();


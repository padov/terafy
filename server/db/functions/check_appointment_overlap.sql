-- Function: check_appointment_overlap
-- Descrição: Verifica se há agendamentos sobrepostos para o mesmo terapeuta
-- Dois intervalos se sobrepõem se: start_time < outro.end_time AND end_time > outro.start_time
-- Exclui agendamentos cancelados e o próprio registro (no caso de UPDATE)
--
-- Quando usar: Trigger BEFORE INSERT/UPDATE na tabela appointments

CREATE OR REPLACE FUNCTION check_appointment_overlap()
RETURNS TRIGGER AS $$
DECLARE
  v_overlapping_count INTEGER;
BEGIN
  -- Verifica se há agendamentos sobrepostos para o mesmo terapeuta
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


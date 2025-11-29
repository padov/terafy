-- Triggers para a tabela appointments
-- Estes triggers dependem das functions:
-- - ft_after_appointment()
-- - check_appointment_overlap()
-- - auto_reschedule_cancelled_appointment()

-- Trigger que executa a função após atualização do status de appointments
CREATE TRIGGER t_after_appointment
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_after_appointment();

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

-- Trigger BEFORE UPDATE para automaticamente reagendar agendamentos cancelados quando editados
CREATE TRIGGER t_auto_reschedule_cancelled_appointment
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (OLD.status = 'cancelled')
EXECUTE FUNCTION auto_reschedule_cancelled_appointment();


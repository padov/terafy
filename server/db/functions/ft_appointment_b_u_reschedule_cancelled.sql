-- Function: ft_appointment_b_u_reschedule_cancelled
-- Trigger: trg_appointment_b_u_reschedule_cancelled
-- Descrição: Automaticamente muda o status de agendamentos cancelados para "reserved" quando editados
-- Tabela: appointments
-- Timing: BEFORE UPDATE
--
-- Comportamento:
-- - Se um agendamento estava cancelado e está sendo atualizado (qualquer campo mudou)
-- - e o status não foi explicitamente alterado para outro valor, muda para "reserved"
-- - Limpa o motivo de cancelamento já que está sendo reagendado

CREATE OR REPLACE FUNCTION ft_appointment_b_u_reschedule_cancelled()
RETURNS TRIGGER AS $$
BEGIN
  -- Se o agendamento estava cancelado e está sendo atualizado (qualquer campo mudou)
  -- e o status não foi explicitamente alterado para outro valor, muda para "reserved"
  IF OLD.status = 'cancelled' AND NEW.status = 'cancelled' THEN
    -- Se qualquer outro campo foi alterado (exceto updated_at que sempre muda)
    IF (
      OLD.start_time IS DISTINCT FROM NEW.start_time
      OR OLD.end_time IS DISTINCT FROM NEW.end_time
      OR OLD.patient_id IS DISTINCT FROM NEW.patient_id
      OR OLD.title IS DISTINCT FROM NEW.title
      OR OLD.description IS DISTINCT FROM NEW.description
      OR OLD.location IS DISTINCT FROM NEW.location
      OR OLD.online_link IS DISTINCT FROM NEW.online_link
      OR OLD.color IS DISTINCT FROM NEW.color
      OR OLD.notes IS DISTINCT FROM NEW.notes
      OR OLD.cancellation_reason IS DISTINCT FROM NEW.cancellation_reason
    ) THEN
      -- Muda automaticamente para "reserved" (agendado)
      NEW.status := 'reserved';
      -- Limpa o motivo de cancelamento já que está sendo reagendado
      NEW.cancellation_reason := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_appointment_b_u_reschedule_cancelled ON appointments;

CREATE TRIGGER trg_appointment_b_u_reschedule_cancelled
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (OLD.status = 'cancelled')
EXECUTE FUNCTION ft_appointment_b_u_reschedule_cancelled();

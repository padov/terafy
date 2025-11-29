-- Function: auto_reschedule_cancelled_appointment
-- Descrição: Automaticamente muda o status de agendamentos cancelados para "reserved" quando editados
-- Quando usar: Trigger BEFORE UPDATE na tabela appointments
--
-- Comportamento:
-- - Se um agendamento estava cancelado e está sendo atualizado (qualquer campo mudou)
-- - e o status não foi explicitamente alterado para outro valor, muda para "reserved"
-- - Limpa o motivo de cancelamento já que está sendo reagendado

CREATE OR REPLACE FUNCTION auto_reschedule_cancelled_appointment()
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



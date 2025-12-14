-- Function: ft_session_a_u_sync_appointment_status
-- Trigger: trg_session_a_u_sync_appointment_status
-- Descrição: Atualiza o status do agendamento vinculado quando a sessão sai do status 'scheduled'
-- Tabela: sessions
-- Timing: AFTER UPDATE
--
-- Comportamento:
-- - Quando uma sessão é iniciada (scheduled -> inProgress) ou completada, o agendamento na agenda é marcado como concluído
-- - Se foi cancelado ou não compareceu -> cancelled
-- - Se foi para inProgress ou completed -> completed

CREATE OR REPLACE FUNCTION ft_session_a_u_sync_appointment_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o status mudou de 'scheduled' para qualquer outra coisa
    -- E se existe um appointment_id vinculado
    IF OLD.status = 'scheduled' AND NEW.status != 'scheduled' AND NEW.appointment_id IS NOT NULL THEN
        
        -- Se foi cancelado ou não compareceu -> cancelled
        IF NEW.status IN ('cancelledByPatient', 'cancelledByTherapist', 'noShow') THEN
            UPDATE appointments
            SET status = 'cancelled',
                updated_at = NOW()
            WHERE id = NEW.appointment_id
            AND status != 'cancelled';
            
        -- Se foi para inProgress ou completed -> completed
        -- (Evita marcar como completed se for apenas 'confirmed' ou voltar para 'draft')
        ELSIF NEW.status IN ('inProgress', 'completed') THEN
             UPDATE appointments
            SET status = 'completed',
                updated_at = NOW()
            WHERE id = NEW.appointment_id
            AND status != 'completed';
        END IF;
        
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_session_a_u_sync_appointment_status ON sessions;

CREATE TRIGGER trg_session_a_u_sync_appointment_status
AFTER UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION ft_session_a_u_sync_appointment_status();

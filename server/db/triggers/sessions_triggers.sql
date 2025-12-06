-- Trigger que atualiza o status do agendamento vinculado quando a sessão sai do status 'scheduled'
-- Objetivo: Quando uma sessão é iniciada (scheduled -> inProgress) ou completada, o agendamento na agenda deve ser marcado como concluído (completed)
-- para liberar a visualização na agenda como algo que já aconteceu/está acontecendo, e não mais um compromisso futuro pendente.

CREATE OR REPLACE FUNCTION update_appointment_status_on_session_change()
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
        PERFORM 1; -- Declaração nula para sintaxe correta do ELSEIF se necessário
        
        ELSEIF NEW.status IN ('inProgress', 'completed') THEN
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

-- Remove a trigger se já existir para recriar
DROP TRIGGER IF EXISTS trigger_update_appointment_status ON sessions;

-- Cria a trigger
CREATE TRIGGER trigger_update_appointment_status
AFTER UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION update_appointment_status_on_session_change();

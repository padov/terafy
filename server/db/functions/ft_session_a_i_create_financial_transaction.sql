-- Function: ft_session_a_i_create_financial_transaction
-- Trigger: trg_session_a_i_create_financial_transaction
-- Descrição: Cria automaticamente uma transação financeira quando uma sessão é criada
-- Tabela: sessions
-- Timing: BEFORE INSERT
--
-- Comportamento:
-- - Se charged_amount estiver definido e > 0, usa esse valor
-- - Se charged_amount for NULL, busca default_session_price do terapeuta
-- - Cria transação financeira do tipo 'income' se houver preço
-- - Define status como 'pending' e payment_method como 'others' por padrão
-- - Vincula a transação ao patient_id e therapist_id
-- - Atualiza o campo transaction_id da sessão com o ID da transação criada

CREATE OR REPLACE FUNCTION ft_session_a_i_create_financial_transaction()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_transaction_id INTEGER;
    session_price DECIMAL(10,2);
BEGIN
    -- Determinar o preço da sessão
    session_price := NEW.charged_amount;
    
    -- Se não houver charged_amount, buscar default_session_price do terapeuta
    IF session_price IS NULL THEN
        SELECT default_session_price INTO session_price
        FROM therapists
        WHERE id = NEW.therapist_id;
    END IF;
    
    -- Criar transação financeira se houver preço definido
    IF session_price IS NOT NULL AND session_price > 0 THEN
        INSERT INTO financial_transactions (
            therapist_id,
            patient_id,
            transaction_date,
            type,
            amount,
            payment_method,
            status,
            category,
            created_at,
            updated_at
        ) VALUES (
            NEW.therapist_id,
            NEW.patient_id,
            CURRENT_DATE,
            'income',
            session_price,
            'others',
            'pending',
            'session',
            NOW(),
            NOW()
        )
        RETURNING id INTO new_transaction_id;
        
        -- Vincular transaction_id na sessão
        NEW.transaction_id := new_transaction_id;
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro completo
        RAISE WARNING 'Erro no trigger ft_session_a_i_create_financial_transaction: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
        -- Retorna NEW para não bloquear o INSERT da sessão
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_session_a_i_create_financial_transaction ON sessions;

CREATE TRIGGER trg_session_a_i_create_financial_transaction
BEFORE INSERT ON sessions
FOR EACH ROW
EXECUTE FUNCTION ft_session_a_i_create_financial_transaction();

-- migrate:up

-- Adicionar 'evaluated' ao ENUM patient_status
-- Usar DO block para evitar erro se o valor já existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'evaluated' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'patient_status')
    ) THEN
        ALTER TYPE patient_status ADD VALUE 'evaluated';
    END IF;
END $$;

-- migrate:down

-- Não é possível remover valores de um ENUM diretamente no PostgreSQL
-- Seria necessário recriar o ENUM, mas isso pode quebrar dados existentes
-- Por isso, deixamos o valor no ENUM mesmo no rollback
-- Se necessário remover no futuro, seguir o mesmo padrão usado em remove_available_from_appointment_status.sql


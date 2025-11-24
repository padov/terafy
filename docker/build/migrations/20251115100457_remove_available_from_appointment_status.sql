-- migrate:up

-- Remove 'available' do ENUM appointment_status
-- Como não podemos remover valores de ENUM diretamente no PostgreSQL,
-- precisamos criar um novo ENUM e migrar os dados

-- Primeiro, verificar se há registros com 'available' e atualizar para 'reserved'
UPDATE appointments 
SET status = 'reserved' 
WHERE status = 'available';

-- Remover o trigger que usa a coluna status antes de alterar o tipo
DROP TRIGGER IF EXISTS t_after_appointment ON appointments;

-- Criar novo ENUM sem 'available'
CREATE TYPE appointment_status_new AS ENUM (
  'reserved',
  'confirmed',
  'completed',
  'cancelled'
);

-- Remover o DEFAULT temporariamente para evitar problemas de conversão
ALTER TABLE appointments 
  ALTER COLUMN status DROP DEFAULT;

-- Alterar a coluna para usar o novo ENUM
ALTER TABLE appointments 
  ALTER COLUMN status TYPE appointment_status_new 
  USING status::text::appointment_status_new;

-- Restaurar o DEFAULT
ALTER TABLE appointments 
  ALTER COLUMN status SET DEFAULT 'reserved';

-- Dropar o ENUM antigo
DROP TYPE appointment_status;

-- Renomear o novo ENUM para o nome original
ALTER TYPE appointment_status_new RENAME TO appointment_status;

-- Recriar a função do trigger com o tipo correto (agora appointment_status sem 'available')
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

-- Recriar o trigger
CREATE TRIGGER t_after_appointment
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_after_appointment();

-- migrate:down

-- Reverter: adicionar 'available' de volta ao ENUM
-- Remover o trigger antes de alterar o tipo
DROP TRIGGER IF EXISTS t_after_appointment ON appointments;

CREATE TYPE appointment_status_old AS ENUM (
  'available',
  'reserved',
  'confirmed',
  'completed',
  'cancelled'
);

-- Remover o DEFAULT temporariamente
ALTER TABLE appointments 
  ALTER COLUMN status DROP DEFAULT;

ALTER TABLE appointments 
  ALTER COLUMN status TYPE appointment_status_old 
  USING status::text::appointment_status_old;

-- Restaurar o DEFAULT
ALTER TABLE appointments 
  ALTER COLUMN status SET DEFAULT 'reserved';

DROP TYPE appointment_status;

ALTER TYPE appointment_status_old RENAME TO appointment_status;

-- Recriar a função do trigger com o tipo antigo
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

-- Recriar o trigger
CREATE TRIGGER t_after_appointment
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_after_appointment();


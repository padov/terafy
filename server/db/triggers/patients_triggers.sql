-- Triggers para a tabela patients
-- Estes triggers dependem das functions:
-- - check_patient_limit()

-- Trigger para verificar limite de pacientes antes de inserir
CREATE TRIGGER trg_check_patient_limit
BEFORE INSERT ON patients
FOR EACH ROW
EXECUTE FUNCTION check_patient_limit();


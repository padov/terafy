-- Triggers para a tabela sessions
-- Estes triggers dependem das functions:
-- - calculate_session_number()
-- - update_sessions_updated_at()

-- Trigger para calcular session_number automaticamente (sequencial por paciente)
CREATE TRIGGER trg_calculate_session_number
BEFORE INSERT ON sessions
FOR EACH ROW
EXECUTE FUNCTION calculate_session_number();

-- Trigger para atualizar updated_at
CREATE TRIGGER trg_update_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION update_sessions_updated_at();


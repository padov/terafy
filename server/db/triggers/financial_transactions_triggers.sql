-- Triggers para a tabela financial_transactions
-- Estes triggers dependem das functions:
-- - update_financial_transactions_updated_at()

-- Trigger para atualizar updated_at
CREATE TRIGGER trg_update_financial_transactions_updated_at
BEFORE UPDATE ON financial_transactions
FOR EACH ROW
EXECUTE FUNCTION update_financial_transactions_updated_at();


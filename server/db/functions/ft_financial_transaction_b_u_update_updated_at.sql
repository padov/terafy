-- Function: ft_financial_transaction_b_u_update_updated_at
-- Trigger: trg_financial_transaction_b_u_update_updated_at
-- Descrição: Atualiza automaticamente o campo updated_at da tabela financial_transactions
-- Tabela: financial_transactions
-- Timing: BEFORE UPDATE
--
-- Comportamento:
-- - Define updated_at para o timestamp atual sempre que um registro é atualizado

CREATE OR REPLACE FUNCTION ft_financial_transaction_b_u_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_financial_transaction_b_u_update_updated_at ON financial_transactions;

CREATE TRIGGER trg_financial_transaction_b_u_update_updated_at
BEFORE UPDATE ON financial_transactions
FOR EACH ROW
EXECUTE FUNCTION ft_financial_transaction_b_u_update_updated_at();

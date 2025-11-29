-- Function: update_financial_transactions_updated_at
-- Descrição: Atualiza automaticamente o campo updated_at da tabela financial_transactions
--
-- Quando usar: Trigger BEFORE UPDATE na tabela financial_transactions

CREATE OR REPLACE FUNCTION update_financial_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


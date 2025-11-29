-- migrate:up

-- Cria tipos ENUM para transações financeiras
CREATE TYPE transaction_type AS ENUM ('recebimento', 'estorno', 'desconto');
CREATE TYPE transaction_status AS ENUM ('pendente', 'pago', 'atrasado', 'cancelado');
CREATE TYPE transaction_category AS ENUM ('sessao', 'avaliacao', 'documento', 'outro');

-- Cria tipo ENUM para formas de pagamento
-- Nota: Já existe payment_method para plan_subscriptions, mas vamos criar um específico para transações
-- para ter mais flexibilidade (inclui convênio, etc.)
CREATE TYPE financial_payment_method AS ENUM (
    'dinheiro',
    'pix',
    'cartao_debito',
    'cartao_credito',
    'transferencia',
    'boleto',
    'convenio'
);

-- Cria a tabela de transações financeiras
CREATE TABLE financial_transactions (
    id SERIAL PRIMARY KEY,
    therapist_id INTEGER NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_id INTEGER NULL REFERENCES sessions(id) ON DELETE SET NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    type transaction_type NOT NULL DEFAULT 'recebimento',
    amount NUMERIC(10, 2) NOT NULL,
    payment_method financial_payment_method NOT NULL,
    status transaction_status NOT NULL DEFAULT 'pendente',
    due_date DATE,
    paid_at TIMESTAMP WITH TIME ZONE,
    receipt_number VARCHAR(50),
    category transaction_category NOT NULL DEFAULT 'sessao',
    notes TEXT,
    invoice_number VARCHAR(50),
    invoice_issued BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_due_date_after_transaction CHECK (due_date IS NULL OR due_date >= transaction_date),
    CONSTRAINT chk_paid_at_after_transaction CHECK (paid_at IS NULL OR paid_at >= transaction_date::timestamp)
);

-- Índices para performance
CREATE INDEX idx_financial_transactions_therapist_id ON financial_transactions(therapist_id);
CREATE INDEX idx_financial_transactions_patient_id ON financial_transactions(patient_id);
CREATE INDEX idx_financial_transactions_session_id ON financial_transactions(session_id);
CREATE INDEX idx_financial_transactions_status ON financial_transactions(status);
CREATE INDEX idx_financial_transactions_transaction_date ON financial_transactions(transaction_date);
CREATE INDEX idx_financial_transactions_due_date ON financial_transactions(due_date);
CREATE INDEX idx_financial_transactions_category ON financial_transactions(category);

-- Triggers serão criados via scripts em triggers/financial_transactions_triggers.sql

-- migrate:down

-- Functions e triggers são gerenciados via pastas functions/ e triggers/
DROP INDEX IF EXISTS idx_financial_transactions_category;
DROP INDEX IF EXISTS idx_financial_transactions_due_date;
DROP INDEX IF EXISTS idx_financial_transactions_transaction_date;
DROP INDEX IF EXISTS idx_financial_transactions_status;
DROP INDEX IF EXISTS idx_financial_transactions_session_id;
DROP INDEX IF EXISTS idx_financial_transactions_patient_id;
DROP INDEX IF EXISTS idx_financial_transactions_therapist_id;

DROP TABLE IF EXISTS financial_transactions;

DROP TYPE IF EXISTS transaction_category;
DROP TYPE IF EXISTS transaction_status;
DROP TYPE IF EXISTS transaction_type;
DROP TYPE IF EXISTS financial_payment_method;


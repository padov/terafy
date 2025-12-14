# Padrão de Nomenclatura de Funções SQL

Este documento define os padrões de nomenclatura e estrutura para funções SQL no projeto Terafy.

## 🎯 Princípio Fundamental

**Funções e Triggers Consolidados:** Cada arquivo de função trigger contém tanto a definição da função quanto a criação do trigger. Isso mantém tudo relacionado em um único lugar, facilitando manutenção e compreensão.

## 📋 Convenções de Nomenclatura

### Funções de Trigger

**Arquivo:** `ft_<table>_<timing>_<event>_<description>.sql`  
**Função:** `ft_<table>_<timing>_<event>_<description>()`  
**Trigger:** `trg_<table>_<timing>_<event>_<description>`

**Componentes:**

- **`ft_`** / **`trg_`** - Prefixos fixos (Function Trigger / Trigger)
- **`<table>`** - Nome da tabela no singular (ex: `appointment`, `session`, `patient`)
- **`<timing>`** - Momento de execução:
  - `b` = BEFORE
  - `a` = AFTER
- **`<event>`** - Tipo de evento:
  - `i` = INSERT
  - `u` = UPDATE
  - `d` = DELETE
  - `iud` = Múltiplos eventos (INSERT, UPDATE, DELETE)
- **`<description>`** - Descrição curta e clara do propósito (snake_case)

**Exemplos:**

| Arquivo                                           | Função                                          | Trigger                                        |
| ------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| `ft_appointment_b_u_reschedule_cancelled.sql`     | `ft_appointment_b_u_reschedule_cancelled()`     | `trg_appointment_b_u_reschedule_cancelled`     |
| `ft_appointment_a_u_sync_patient_stats.sql`       | `ft_appointment_a_u_sync_patient_stats()`       | `trg_appointment_a_u_sync_patient_stats`       |
| `ft_session_a_i_create_financial_transaction.sql` | `ft_session_a_i_create_financial_transaction()` | `trg_session_a_i_create_financial_transaction` |

### Funções Utilitárias (não-trigger)

**Arquivo:** `fn_<description>.sql`  
**Função:** `fn_<description>()`  
**Trigger(s):** `trg_<table>_<timing><event>_<description>` (quando aplicável)

**Componentes:**

- **`fn_`** - Prefixo fixo (Function)
- **`<description>`** - Descrição clara e completa do propósito (snake_case)

**Exemplos:**

```
fn_calculate_session_number.sql
fn_check_appointment_overlap.sql
fn_get_patient_statistics.sql
```

**Nota:** Funções utilitárias que são usadas por triggers também devem incluir a criação dos triggers no mesmo arquivo.

---

## 📝 Template de Função Trigger

**IMPORTANTE:** Cada arquivo deve conter tanto a função quanto o trigger.

```sql
-- Function: ft_<table>_<timing>_<event>_<description>
-- Trigger: trg_<table>_<timing>_<event>_<description>
-- Descrição: [Explicação detalhada do que a função faz]
-- Tabela: <table_name>
-- Timing: <BEFORE|AFTER> <INSERT|UPDATE|DELETE>
--
-- Comportamento:
-- - [Ponto 1]
-- - [Ponto 2]
-- - [Ponto 3]

CREATE OR REPLACE FUNCTION ft_<table>_<timing>_<event>_<description>()
RETURNS TRIGGER AS $$
DECLARE
  -- Variáveis locais (se necessário)
BEGIN
  -- Lógica da função

  RETURN NEW; -- ou OLD para DELETE, ou NULL para cancelar operação
END;
$$ LANGUAGE plpgsql;
```

## 📝 Template de Função Utilitária

**IMPORTANTE:** Se a função utilitária for usada por triggers, inclua a criação dos triggers no mesmo arquivo.

```sql
-- Function: fn_<description>
-- Trigger(s): trg_<table>_<timing><event>_<description> (se aplicável)
-- Descrição: [Explicação detalhada do que a função faz]
-- Parâmetros:
--   - param1: [tipo] - [descrição]
--   - param2: [tipo] - [descrição]
-- Retorna: [tipo] - [descrição do retorno]
--
-- Exemplo de uso:
-- SELECT fn_<description>(param1, param2);

CREATE OR REPLACE FUNCTION fn_<description>(
  param1 TYPE,
  param2 TYPE
)
RETURNS RETURN_TYPE AS $$
DECLARE
  -- Variáveis locais
BEGIN
  -- Lógica da função

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger(s) se a função for usada como trigger
DROP TRIGGER IF EXISTS trg_<table>_<timing><event>_<description> ON <table_name>;

CREATE TRIGGER trg_<table>_<timing><event>_<description>
<BEFORE|AFTER> <INSERT|UPDATE|DELETE> ON <table_name>
FOR EACH ROW
EXECUTE FUNCTION fn_<description>();
```

---

## 🤖 Prompts para Criação de Funções

### Prompt: Criar Função Trigger

```
Crie uma função trigger SQL seguindo o padrão do projeto Terafy:

Tabela: [nome_da_tabela]
Timing: [BEFORE/AFTER]
Evento: [INSERT/UPDATE/DELETE]
Descrição: [o que a função deve fazer]

Requisitos:
- Seguir o padrão de nomenclatura:
  - Arquivo: ft_<table>_<timing>_<event>_<description>.sql
  - Função: ft_<table>_<timing>_<event>_<description>()
  - Trigger: trg_<table>_<timing>_<event>_<description>
- Incluir TANTO a função QUANTO o trigger no mesmo arquivo
- Incluir comentários detalhados no cabeçalho
- Documentar comportamento esperado
- Usar tratamento de erros quando apropriado
- Considerar casos edge (NULL, valores vazios, etc.)

Contexto adicional: [informações relevantes sobre a lógica de negócio]
```

### Prompt: Criar Função Utilitária

```
Crie uma função utilitária SQL seguindo o padrão do projeto Terafy:

Nome: fn_[descrição]
Propósito: [o que a função deve fazer]
Parâmetros:
  - [nome]: [tipo] - [descrição]
  - [nome]: [tipo] - [descrição]
Retorno: [tipo] - [descrição]
Usada como trigger: [SIM/NÃO]

Requisitos:
- Seguir o padrão de nomenclatura:
  - Arquivo: fn_<description>.sql
  - Função: fn_<description>()
  - Trigger (se aplicável): trg_<table>_<timing><event>_<description>
- Se for usada como trigger, incluir a criação do trigger no mesmo arquivo
- Incluir comentários detalhados no cabeçalho
- Documentar todos os parâmetros e retorno
- Incluir exemplo de uso
- Usar tratamento de erros quando apropriado
- Otimizar para performance quando possível

Contexto adicional: [informações relevantes sobre a lógica de negócio]
```

### Prompt: Refatorar Função Existente

```
Refatore a função SQL @[caminho/para/funcao.sql] para seguir o padrão do projeto Terafy:

Ações necessárias:
1. Renomear arquivo seguindo o padrão ft_<table>_<timing>_<event>_<description>.sql ou fn_<description>.sql
2. Atualizar nome da função no código
3. Adicionar/melhorar comentários de cabeçalho
4. Documentar comportamento, parâmetros e retorno
5. Incluir exemplo de uso
6. Atualizar referências em migrations e código

Mantenha a lógica existente, apenas melhore a documentação e nomenclatura.
```

---

## 🎯 Boas Práticas

### Nomenclatura

- ✅ Use snake_case para nomes de funções e variáveis
- ✅ Seja descritivo mas conciso
- ✅ Use verbos para ações (update, create, calculate, check)
- ❌ Evite abreviações obscuras
- ❌ Não use prefixos genéricos como "do*", "handle*"

### Documentação

- ✅ Sempre inclua comentário de cabeçalho completo
- ✅ Documente casos especiais e edge cases
- ✅ Inclua exemplo de uso/criação do trigger
- ✅ Explique o "porquê", não apenas o "o quê"

### Código

- ✅ Use DECLARE para variáveis locais
- ✅ Prefixe variáveis locais com `v_` (ex: `v_total_sessions`)
- ✅ Trate valores NULL explicitamente quando relevante
- ✅ Use `IS DISTINCT FROM` para comparações que consideram NULL
- ✅ Adicione validações de entrada quando apropriado

### Performance

- ✅ Minimize queries dentro de loops
- ✅ Use índices apropriados nas tabelas
- ✅ Considere o impacto em operações em lote
- ✅ Evite lógica complexa em triggers BEFORE quando possível

---

## 📚 Exemplos Reais do Projeto

### Exemplo 1: Trigger BEFORE UPDATE

**Arquivo:** `ft_appointment_b_u_reschedule_cancelled.sql`

```sql
-- Function: ft_appointment_b_u_reschedule_cancelled
-- Trigger: trg_appointment_b_u_reschedule_cancelled
-- Descrição: Automaticamente muda o status de agendamentos cancelados para "reserved" quando editados
-- Tabela: appointments
-- Timing: BEFORE UPDATE
--
-- Comportamento:
-- - Se um agendamento estava cancelado e está sendo atualizado (qualquer campo mudou)
-- - e o status não foi explicitamente alterado para outro valor, muda para "reserved"
-- - Limpa o motivo de cancelamento já que está sendo reagendado

CREATE OR REPLACE FUNCTION ft_appointment_b_u_reschedule_cancelled()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'cancelled' AND NEW.status = 'cancelled' THEN
    IF (
      OLD.start_time IS DISTINCT FROM NEW.start_time
      OR OLD.end_time IS DISTINCT FROM NEW.end_time
      OR OLD.patient_id IS DISTINCT FROM NEW.patient_id
    ) THEN
      NEW.status := 'reserved';
      NEW.cancellation_reason := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_appointment_b_u_reschedule_cancelled ON appointments;

CREATE TRIGGER trg_appointment_b_u_reschedule_cancelled
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (OLD.status = 'cancelled')
EXECUTE FUNCTION ft_appointment_b_u_reschedule_cancelled();
```

### Exemplo 2: Trigger AFTER UPDATE

**Arquivo:** `ft_appointment_a_u_sync_patient_stats.sql`

```sql
-- Function: ft_appointment_a_u_sync_patient_stats
-- Trigger: trg_appointment_a_u_sync_patient_stats
-- Descrição: Atualiza total_sessions e last_session_date em patients
-- quando o status de um appointment é alterado para 'completed' ou de 'completed' para outro status
-- Tabela: appointments
-- Timing: AFTER UPDATE OF status

CREATE OR REPLACE FUNCTION ft_appointment_a_u_sync_patient_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_total_sessions INTEGER;
  v_last_session_date DATE;
BEGIN
  -- Se o status foi alterado para completado
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE patients
    SET total_sessions = total_sessions + 1,
        last_session_date = NEW.start_time
    WHERE id = NEW.patient_id;
  END IF;

  -- Se o status foi alterado de completado para outro
  IF NEW.status != 'completed' AND OLD.status = 'completed' THEN
    SELECT COUNT(*), MAX(start_time)
    INTO v_total_sessions, v_last_session_date
    FROM appointments
    WHERE patient_id = NEW.patient_id
      AND type = 'session'::appointment_type
      AND status = 'completed'::appointment_status;

    UPDATE patients
    SET total_sessions = v_total_sessions,
        last_session_date = v_last_session_date
    WHERE id = NEW.patient_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trg_appointment_a_u_sync_patient_stats ON appointments;

CREATE TRIGGER trg_appointment_a_u_sync_patient_stats
AFTER UPDATE OF status ON appointments
FOR EACH ROW
EXECUTE FUNCTION ft_appointment_a_u_sync_patient_stats();
```

### Exemplo 3: Função Utilitária com Triggers

**Arquivo:** `fn_check_appointment_overlap.sql`

```sql
-- Function: fn_check_appointment_overlap
-- Trigger(s): trg_appointment_bi_check_overlap, trg_appointment_bu_check_overlap
-- Descrição: Verifica se há agendamentos sobrepostos para o mesmo terapeuta
-- Tabela: appointments
-- Timing: BEFORE INSERT, BEFORE UPDATE
--
-- Comportamento:
-- - Verifica se há conflito de horário para o mesmo terapeuta
-- - Dois intervalos se sobrepõem se: start_time < outro.end_time AND end_time > outro.start_time
-- - Exclui agendamentos cancelados da verificação
-- - Exclui o próprio registro (no caso de UPDATE)
-- - Lança exceção se houver sobreposição

CREATE OR REPLACE FUNCTION fn_check_appointment_overlap()
RETURNS TRIGGER
SECURITY DEFINER  -- Executa com privilégios do dono da função para contornar RLS
AS $$
DECLARE
  v_overlapping_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_overlapping_count
  FROM appointments
  WHERE therapist_id = NEW.therapist_id
    AND id != COALESCE(NEW.id, 0)
    AND status != 'cancelled'
    AND start_time < NEW.end_time
    AND end_time > NEW.start_time;

  IF v_overlapping_count > 0 THEN
    RAISE EXCEPTION 'Conflito de horário: já existe um agendamento para este terapeuta no período de % a %',
      NEW.start_time, NEW.end_time;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar triggers
DROP TRIGGER IF EXISTS trg_appointment_bi_check_overlap ON appointments;
DROP TRIGGER IF EXISTS trg_appointment_bu_check_overlap ON appointments;

CREATE TRIGGER trg_appointment_bi_check_overlap
BEFORE INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION fn_check_appointment_overlap();

CREATE TRIGGER trg_appointment_bu_check_overlap
BEFORE UPDATE ON appointments
FOR EACH ROW
WHEN (
  OLD.start_time IS DISTINCT FROM NEW.start_time
  OR OLD.end_time IS DISTINCT FROM NEW.end_time
  OR OLD.therapist_id IS DISTINCT FROM NEW.therapist_id
  OR OLD.status IS DISTINCT FROM NEW.status
)
EXECUTE FUNCTION fn_check_appointment_overlap();
```

---

## 🔄 Processo de Criação/Atualização

### Criar Nova Função Trigger

1. **Criar arquivo** seguindo o padrão `ft_<table>_<timing>_<event>_<description>.sql`
2. **Incluir função E trigger** no mesmo arquivo
3. **Documentar** completamente no cabeçalho
4. **Testar** localmente com `make server-dev`
5. **Commitar** com mensagem descritiva

### Atualizar Função Trigger Existente

1. **Editar arquivo** da função
2. **Atualizar função** (CREATE OR REPLACE)
3. **Atualizar trigger** se necessário (DROP + CREATE)
4. **Testar** localmente
5. **Commitar** com mensagem descritiva

**Nota:** Não é necessário criar migrations para funções/triggers. O `migration_manager` recria automaticamente todas as funções após executar as migrations.

### Renomear Função Existente

1. **Criar novo arquivo** com o nome correto
2. **Copiar e ajustar** função e trigger
3. **Testar** todas as funcionalidades afetadas
4. **Remover arquivo antigo** após confirmação
5. **Commitar** com mensagem descritiva

---

## 📂 Estrutura de Diretórios

```
server/db/
├── functions/
│   ├── ft_appointment_a_u_sync_patient_stats.sql
│   ├── ft_appointment_b_u_reschedule_cancelled.sql
│   ├── ft_financial_transaction_b_u_update_updated_at.sql
│   ├── ft_session_a_i_create_financial_transaction.sql
│   ├── ft_session_a_u_sync_appointment_status.sql
│   ├── ft_session_b_u_update_updated_at.sql
│   ├── fn_calculate_session_number.sql
│   └── fn_check_appointment_overlap.sql
├── migrations/
│   └── ... (migrations ordenadas por timestamp)
└── policies/
    └── ... (policies RLS)
```

**Importante:** Não existe mais a pasta `triggers/`. Todos os triggers estão consolidados com suas funções na pasta `functions/`.

---

## 📖 Referências

- [PostgreSQL Trigger Functions](https://www.postgresql.org/docs/current/plpgsql-trigger.html)
- [PostgreSQL Functions](https://www.postgresql.org/docs/current/sql-createfunction.html)
- [Best Practices for PostgreSQL Triggers](https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don.27t_use_triggers)

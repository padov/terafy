# ENUM vs INT: Comparação para Campos de Status

## ENUM (Atual)

### ✅ Vantagens
1. **Integridade de dados garantida pelo banco**
   - PostgreSQL não permite valores inválidos
   - Exemplo: não pode inserir `status = 'invalid'` ou `status = 999`

2. **Queries mais legíveis**
   ```sql
   SELECT * FROM users WHERE status = 'active';  -- Legível
   SELECT * FROM users WHERE status = 1;          -- Preciso saber o mapeamento
   ```

3. **Autodocumentado**
   - O próprio banco documenta os valores permitidos
   - Facilita para outros desenvolvedores/DBAs

4. **Menos código no aplicativo**
   - Não precisa manter tabela de mapeamento
   - Não precisa validar no código Dart

### ❌ Desvantagens
1. **Problema com driver Dart**
   - Retorna como `UndecodedBytes`
   - Precisa fazer CAST `::text` nas queries OU tratar no código

2. **Migrações mais complexas**
   - Adicionar novo valor requer `ALTER TYPE`
   - Mais difícil de fazer rollback

3. **Portabilidade**
   - Alguns bancos não suportam ENUM nativamente
   - Mais difícil migrar para outro banco

## INT (Alternativa)

### ✅ Vantagens
1. **Suporte nativo do driver Dart**
   - Não precisa de CAST
   - Não precisa tratar `UndecodedBytes`
   - Código mais simples

2. **Migrações mais fáceis**
   - Adicionar novo valor = apenas adicionar no código
   - Não precisa alterar estrutura do banco

3. **Performance ligeiramente melhor**
   - INT ocupa menos espaço (4 bytes vs variável)
   - Índices menores

4. **Portabilidade**
   - Todos os bancos suportam INT
   - Fácil migrar para outro banco

5. **Flexibilidade**
   - Pode usar bit flags para múltiplos estados
   - Pode ordenar numericamente

### ❌ Desvantagens
1. **Perde integridade no banco**
   - Pode inserir `status = 999` (valor inválido)
   - Precisa garantir integridade no código da aplicação

2. **Menos legível**
   ```sql
   SELECT * FROM users WHERE status = 1;  -- O que é 1?
   ```
   - Precisa consultar documentação/código para saber o significado
   - Queries menos autodocumentadas

3. **Precisa manter mapeamento**
   ```dart
   // No código Dart
   enum UserStatus { active = 1, suspended = 2, canceled = 3 }
   ```
   - Risco de desincronização entre banco e código
   - Precisa validar no código Dart

4. **Fácil de fazer erros**
   - Desenvolvedor pode esquecer o mapeamento
   - Valores mágicos no código

## Comparação Prática

### Com ENUM (Atual)
```sql
-- Migration
CREATE TYPE account_status AS ENUM ('active', 'suspended', 'canceled');
ALTER TABLE users ADD COLUMN status account_status DEFAULT 'active';

-- Query (com CAST)
SELECT status::text FROM users WHERE status = 'active';

-- Código Dart
status: map['status'] as String  // Já vem como String após CAST
```

### Com INT (Alternativa)
```sql
-- Migration
ALTER TABLE users ADD COLUMN status INT DEFAULT 1;

-- Query (sem CAST)
SELECT status FROM users WHERE status = 1;

-- Código Dart
enum UserStatus { active = 1, suspended = 2, canceled = 3 }
status: UserStatus.values.firstWhere((e) => e.index + 1 == map['status'] as int)
```

## Recomendação

### Mantenha ENUM se:
- ✅ Integridade de dados é crítica
- ✅ Time tem experiência com PostgreSQL
- ✅ Não planeja migrar para outro banco
- ✅ Quer queries legíveis e autodocumentadas

**Solução atual é boa:** CAST `::text` resolve o problema do UndecodedBytes sem perder as vantagens do ENUM.

### Use INT se:
- ✅ Quer código mais simples (sem CAST)
- ✅ Precisa de fácil portabilidade entre bancos
- ✅ Valoriza performance máxima
- ✅ Time é disciplinado para manter integridade no código

## Solução Híbrida (Melhor dos dois mundos)

Manter ENUM no banco MAS criar constantes no código Dart:

```dart
// constants.dart
class UserStatus {
  static const String active = 'active';
  static const String suspended = 'suspended';
  static const String canceled = 'canceled';
}

// Uso
UserStatus.values.firstWhere((e) => e == map['status'])
```

Assim você tem:
- ✅ Integridade do ENUM no banco
- ✅ Código Dart legível e type-safe
- ✅ CAST `::text` resolve UndecodedBytes
- ✅ Queries legíveis: `WHERE status = 'active'`

## Conclusão

**Recomendação:** **Mantenha ENUM** com a solução atual (CAST `::text`).

**Por quê?**
- Você já resolveu o problema do UndecodedBytes
- Mantém integridade de dados no banco
- Queries permanecem legíveis
- Não precisa validar no código Dart

**Mude para INT apenas se:**
- O CAST estiver causando problemas de performance
- Precisar migrar para outro banco que não suporta ENUM
- Quiser simplificar o código (mas perde integridade)

## Exemplo: Se escolher INT

### Migration
```sql
-- Remover ENUM e criar como INT
ALTER TABLE users DROP COLUMN status;
ALTER TABLE users ADD COLUMN status INT NOT NULL DEFAULT 1;
-- 1 = active, 2 = suspended, 3 = canceled

-- Com constraint para garantir valores válidos
ALTER TABLE users ADD CONSTRAINT check_status 
  CHECK (status IN (1, 2, 3));
```

### Código Dart
```dart
enum UserStatus { active = 1, suspended = 2, canceled = 3 }

// No modelo
final UserStatus status;

// No fromMap
status: UserStatus.values.firstWhere(
  (e) => e.index + 1 == (map['status'] as int),
  orElse: () => UserStatus.active,
);

// No repository (sem CAST)
SELECT status FROM users WHERE status = 1;
```


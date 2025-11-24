# O que é o `accountId` no Token JWT?

## 📋 Conceito

O `accountId` no token JWT representa o **ID da conta vinculada** ao usuário. É uma referência polimórfica que pode apontar para:
- `therapist_id` (se `account_type = 'therapist'`)
- `patient_id` (se `account_type = 'patient'`)

## 🔗 Relação entre Tabelas

```
┌─────────────┐         ┌──────────────┐
│    users    │         │  therapists  │
├─────────────┤         ├──────────────┤
│ id (PK)     │─────────│ id (PK)      │
│ email       │         │ name         │
│ role        │         │ email        │
│ account_type│         │ user_id (FK) │
│ account_id  │─────────┘              │
└─────────────┘         └──────────────┘
     │
     │ account_id aponta para therapists.id
     │ (quando account_type = 'therapist')
```

## 📊 Estrutura no Banco de Dados

### Tabela `users`:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255),
    role user_role,              -- 'therapist', 'patient', 'admin'
    account_type account_type,  -- 'therapist' ou 'patient' (nullable)
    account_id INTEGER,          -- FK para therapists.id ou patients.id (nullable)
    ...
);
```

### Exemplo de Dados:

**Usuário recém-cadastrado (sem perfil completo):**
```sql
id: 1
email: 'novo@terafy.com'
role: 'therapist'
account_type: NULL          ← Ainda não tem conta vinculada
account_id: NULL            ← Ainda não tem ID da conta
```

**Usuário com perfil de terapeuta completo:**
```sql
id: 1
email: 'terapeuta@terafy.com'
role: 'therapist'
account_type: 'therapist'   ← Tipo da conta vinculada
account_id: 123             ← ID do therapist na tabela therapists
```

## 🔑 Como aparece no Token JWT

### Token de usuário recém-cadastrado:
```json
{
  "sub": "1",
  "email": "novo@terafy.com",
  "role": "therapist",
  "account_type": null,      ← null (ainda não completou perfil)
  "account_id": null,        ← null (ainda não tem therapist_id)
  "iat": 1700000000,
  "exp": 1700604800
}
```

### Token de usuário com perfil completo:
```json
{
  "sub": "1",
  "email": "terapeuta@terafy.com",
  "role": "therapist",
  "account_type": "therapist",  ← Tipo da conta
  "account_id": 123,            ← ID do therapist (therapists.id)
  "iat": 1700000000,
  "exp": 1700604800
}
```

## 🔄 Fluxo de Preenchimento

### 1. Registro (`POST /auth/register`):
```dart
// Usuário criado sem account_type e account_id
User(
  email: 'novo@terafy.com',
  role: 'therapist',
  accountType: null,    // ← null inicialmente
  accountId: null,      // ← null inicialmente
)
```

### 2. Completar Perfil (`POST /therapists`):
```dart
// Cria therapist
final therapist = await createTherapist(...); // therapist.id = 123

// Atualiza usuário com account_type e account_id
await updateUserAccount(
  userId: 1,
  accountType: 'therapist',
  accountId: 123,  // ← therapist.id
);

// Vincula therapist ao usuário
await updateTherapistUserId(
  therapistId: 123,
  userId: 1,
);
```

### 3. Próximo Login:
```dart
// Token gerado agora inclui account_id
JwtService.generateToken(
  userId: 1,
  email: 'terapeuta@terafy.com',
  role: 'therapist',
  accountType: 'therapist',  // ← Preenchido
  accountId: 123,            // ← Preenchido (therapist.id)
);
```

## 🛡️ Uso no RLS (Row Level Security)

O `accountId` pode ser usado no contexto RLS para verificar acesso:

```dart
// No handler, extrai accountId do token
final accountId = getAccountId(request); // 123 (therapist.id)

// Passa para repository com contexto RLS
await RLSContext.setContext(
  conn: conn,
  userId: userId,        // 1 (user.id)
  userRole: userRole,    // 'therapist'
  accountId: accountId,  // 123 (therapist.id)
);

// No PostgreSQL, pode usar nas policies:
CREATE POLICY therapist_policy ON therapists
  USING (
    user_id = current_setting('app.user_id', true)::int
    OR
    id = current_setting('app.account_id', true)::int  -- ← Usa accountId
  );
```

## 💡 Vantagens de Usar `accountId`

1. **Acesso rápido**: Não precisa fazer JOIN para saber o therapist_id
2. **Cache no token**: Informação disponível sem consultar banco
3. **RLS simplificado**: Pode usar diretamente nas policies
4. **Verificação de propriedade**: Facilita verificar se usuário é dono do recurso

## 📝 Exemplo Prático

### Handler usando `accountId`:

```dart
Future<Response> handleUpdateMe(Request request) async {
  final userId = getUserId(request);        // 1 (user.id)
  final accountId = getAccountId(request);  // 123 (therapist.id)
  
  if (accountId == null) {
    return badRequestResponse(
      'Usuário não possui perfil de terapeuta vinculado',
    );
  }
  
  // Usa accountId diretamente (já é o therapist.id)
  final therapist = await _controller.updateTherapist(
    accountId,  // ← 123 (therapist.id)
    therapist,
    userId: userId,
    accountId: accountId,
  );
}
```

### Comparação:

**Sem `accountId` no token:**
```dart
// Precisa buscar therapist pelo user_id
final therapist = await repository.getTherapistByUserId(userId);
final therapistId = therapist.id; // 123
```

**Com `accountId` no token:**
```dart
// Já tem o therapist.id no token!
final therapistId = getAccountId(request); // 123
```

## ⚠️ Importante

- `accountId` é **nullable** porque usuários recém-cadastrados ainda não têm perfil completo
- Sempre verifique se `accountId != null` antes de usar
- O `accountId` corresponde ao `id` da tabela `therapists` (ou `patients`)
- Quando `account_type = 'therapist'`, então `account_id = therapists.id`
- Quando `account_type = 'patient'`, então `account_id = patients.id`

## 🔍 Resumo

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `sub` (userId) | ID do usuário na tabela `users` | `1` |
| `account_type` | Tipo da conta vinculada | `'therapist'` ou `'patient'` |
| `account_id` | ID da conta vinculada (therapist_id ou patient_id) | `123` |

**Relação:**
- Se `account_type = 'therapist'` → `account_id = therapists.id`
- Se `account_type = 'patient'` → `account_id = patients.id`
- Se `account_type = null` → `account_id = null` (usuário sem perfil completo)


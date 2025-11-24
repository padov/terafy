# Estrutura do Token JWT

## 📋 Visão Geral

O token JWT contém informações sobre o usuário autenticado, incluindo sua role, que é usada para controle de acesso nas rotas da API.

## 🔑 Claims do Token

O token JWT gerado contém os seguintes claims (campos):

```json
{
  "sub": "1",                    // User ID (Subject)
  "email": "usuario@exemplo.com",
  "role": "therapist",           // Role do usuário: 'therapist', 'patient', ou 'admin'
  "account_type": "therapist",   // Tipo de conta vinculada (pode ser null)
  "account_id": 123,             // ID da conta vinculada (pode ser null)
  "iat": 1700000000,            // Issued At (timestamp de emissão)
  "exp": 1700604800             // Expiration (timestamp de expiração)
}
```

## 📝 Detalhamento dos Campos

### `sub` (Subject)
- **Tipo**: String (representa o User ID)
- **Descrição**: ID único do usuário no sistema
- **Exemplo**: `"1"`, `"42"`

### `email`
- **Tipo**: String
- **Descrição**: Email do usuário autenticado
- **Exemplo**: `"terapeuta@terafy.com"`

### `role` ⭐
- **Tipo**: String
- **Descrição**: Role do usuário no sistema
- **Valores possíveis**:
  - `"therapist"` - Terapeuta (padrão para novos registros)
  - `"patient"` - Paciente
  - `"admin"` - Administrador (não disponível via login ainda)
- **Uso**: Usado para controle de acesso nas rotas (`requireRole()`, `checkResourceAccess()`)

### `account_type`
- **Tipo**: String ou null
- **Descrição**: Tipo de conta vinculada ao usuário
- **Valores possíveis**:
  - `"therapist"` - Conta de terapeuta vinculada
  - `"patient"` - Conta de paciente vinculada
  - `null` - Nenhuma conta vinculada (usuário recém-cadastrado)
- **Nota**: Preenchido após completar o perfil

### `account_id`
- **Tipo**: Integer ou null
- **Descrição**: ID da conta vinculada (therapist_id ou patient_id)
- **Exemplo**: `123`, `456`
- **Nota**: Preenchido após completar o perfil

### `iat` (Issued At)
- **Tipo**: Integer (Unix timestamp)
- **Descrição**: Momento em que o token foi emitido
- **Exemplo**: `1700000000`

### `exp` (Expiration)
- **Tipo**: Integer (Unix timestamp)
- **Descrição**: Momento em que o token expira
- **Padrão**: 7 dias após a emissão (configurável via `JWT_EXPIRATION_DAYS` no `.env`)
- **Exemplo**: `1700604800`

## 🔄 Fluxo de Geração do Token

### 1. Login (`POST /auth/login`)
```dart
// No AuthController.login()
final token = JwtService.generateToken(
  userId: user.id!,
  email: user.email,
  role: user.role,              // ✅ Role vem do banco de dados
  accountType: user.accountType, // Pode ser null
  accountId: user.accountId,     // Pode ser null
);
```

### 2. Registro (`POST /auth/register`)
```dart
// No AuthController.register()
final newUser = User(
  role: 'therapist',  // ✅ Sempre 'therapist' para novos registros
  accountType: null,   // Será preenchido após completar perfil
  accountId: null,     // Será preenchido após completar perfil
);

final token = JwtService.generateToken(
  userId: createdUser.id!,
  email: createdUser.email,
  role: createdUser.role,        // ✅ 'therapist'
  accountType: null,             // null inicialmente
  accountId: null,                // null inicialmente
);
```

## 🔐 Uso do Token no Middleware

O middleware `authMiddleware()` extrai as informações do token e adiciona aos headers do request:

```dart
// Extraído do token JWT
'x-user-id': claims['sub']        // "1"
'x-user-role': claims['role']     // "therapist" ⭐
'x-account-type': claims['account_type'] ?? ''  // "therapist" ou ""
'x-account-id': claims['account_id']?.toString() ?? ''  // "123" ou ""
```

## 🛡️ Controle de Acesso Baseado em Role

### Exemplo 1: Rota apenas para admin
```dart
router.get('/', requireRole('admin').call(handler.handleGetAll));
```

### Exemplo 2: Rota para therapist
```dart
router.get('/me', requireRole('therapist').call(handler.handleGetMe));
```

### Exemplo 3: Verificação de acesso a recurso
```dart
final accessError = checkResourceAccess(
  request: request,
  resourceId: therapistId,
  allowedRoles: ['therapist', 'admin'], // ✅ Verifica role do token
);
```

## 📊 Exemplo de Token Decodificado

### Token de um terapeuta recém-cadastrado:
```json
{
  "sub": "1",
  "email": "terapeuta@terafy.com",
  "role": "therapist",
  "account_type": null,
  "account_id": null,
  "iat": 1700000000,
  "exp": 1700604800
}
```

### Token de um terapeuta com perfil completo:
```json
{
  "sub": "1",
  "email": "terapeuta@terafy.com",
  "role": "therapist",
  "account_type": "therapist",
  "account_id": 123,
  "iat": 1700000000,
  "exp": 1700604800
}
```

## 🧪 Como Testar

### 1. Fazer login e obter o token:
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "teste@terafy.com", "password": "senha123"}'
```

### 2. Decodificar o token:
```bash
dart run bin/decode_token.dart <seu_token_aqui>
```

### 3. Usar o token em uma requisição:
```bash
curl -X GET http://localhost:8080/therapists/me \
  -H "Authorization: Bearer <seu_token_aqui>"
```

## ⚠️ Notas Importantes

1. **Role padrão**: Todos os novos registros recebem `role: 'therapist'`
2. **Admin não disponível**: Por enquanto, não há login com usuários admin
3. **Account vinculada**: `account_type` e `account_id` são preenchidos após completar o perfil
4. **Validação**: O token é validado em todas as rotas protegidas pelo `authMiddleware()`
5. **Expiração**: Tokens expiram em 7 dias (configurável via `.env`)

## 🔄 Atualização do Token

Quando o usuário completa seu perfil (cria therapist), o token precisa ser atualizado para incluir `account_type` e `account_id`. Isso pode ser feito:

1. **Re-login**: Usuário faz login novamente após completar perfil
2. **Refresh token**: Implementar endpoint de refresh (futuro)
3. **Atualização automática**: Atualizar token após criar therapist (futuro)


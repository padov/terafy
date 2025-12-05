# Implementação Refresh Token + Blacklist

## ✅ O que foi implementado

### 1. Migrations Criadas

#### `20251105000000_create_refresh_tokens_table.sql`

- Tabela `refresh_tokens` para armazenar refresh tokens
- Campos: `id` (UUID), `user_id`, `token_hash`, `expires_at`, `revoked`, `device_info`, `ip_address`
- Índices para performance

#### `20251105000001_create_token_blacklist_table.sql`

- Tabela `token_blacklist` para tokens revogados
- Campos: `token_id` (JTI), `user_id`, `expires_at`, `revoked_at`, `reason`
- Índices para limpeza automática

### 2. Repositories Criados

#### `RefreshTokenRepository`

- `createRefreshToken()` - Cria novo refresh token
- `findTokenByHash()` - Busca token pelo hash
- `updateLastUsed()` - Atualiza último uso
- `revokeToken()` - Revoga um token específico
- `revokeAllUserTokens()` - Revoga todos os tokens de um usuário
- `deleteExpiredTokens()` - Limpeza de tokens expirados
- `getUserTokens()` - Lista tokens de um usuário

#### `TokenBlacklistRepository`

- `addToBlacklist()` - Adiciona token à blacklist
- `isBlacklisted()` - Verifica se token está na blacklist
- `deleteExpiredTokens()` - Limpeza de tokens expirados
- `blacklistAllUserTokens()` - Blacklist todos os tokens de um usuário

### 3. JwtService Modificado

#### Novos Métodos:

- `generateAccessToken()` - Gera access token (15 minutos)
- `generateRefreshToken()` - Gera refresh token (7 dias)
- `generateToken()` - Mantido para compatibilidade (deprecated)

#### Configurações:

- `JWT_ACCESS_TOKEN_EXPIRATION_MINUTES` (padrão: 15)
- `JWT_REFRESH_TOKEN_EXPIRATION_DAYS` (padrão: 7)

### 4. AuthController Modificado

#### Novos Métodos:

- `refreshAccessToken()` - Renova access token usando refresh token
- `revokeRefreshToken()` - Revoga refresh token e adiciona à blacklist

#### Modificações:

- `login()` - Agora gera access token + refresh token separados
- `register()` - Agora gera access token + refresh token separados

### 5. AuthHandler Modificado

#### Novos Endpoints:

- `POST /auth/refresh` - Renova access token
- `POST /auth/logout` - Revoga tokens

### 6. AuthMiddleware Modificado

#### Novas Funcionalidades:

- Verifica se token é `access` (não `refresh`)
- Verifica blacklist antes de permitir acesso
- `/auth/refresh` adicionado às rotas públicas

## 🔄 Fluxo Completo

### 1. Login

```
POST /auth/login
{
  "email": "user@example.com",
  "password": "senha123"
}

Resposta:
{
  "auth_token": "eyJ...",      // Access token (15min)
  "refresh_token": "eyJ...",   // Refresh token (7 dias)
  "user": {...}
}
```

### 2. Usar Access Token

```
GET /therapists/me
Authorization: Bearer <access_token>

✅ Funciona por 15 minutos
```

### 3. Access Token Expira

```
GET /therapists/me
Authorization: Bearer <access_token_expirado>

❌ 401 Unauthorized
```

### 4. Renovar Access Token

```
POST /auth/refresh
{
  "refresh_token": "eyJ..."
}

Resposta:
{
  "access_token": "eyJ...",    // Novo access token (15min)
  "refresh_token": "eyJ..."    // Mesmo refresh token
}
```

### 5. Logout

```
POST /auth/logout
Authorization: Bearer <access_token>
{
  "refresh_token": "eyJ..."
}

✅ Refresh token revogado
✅ Access token adicionado à blacklist
```

## 🛡️ Segurança

### Access Token

- **Duração**: 15 minutos
- **Uso**: Todas as requisições autenticadas
- **Revogação**: Via blacklist (logout)
- **Conteúdo**: userId, email, role, accountType, accountId, jti

### Refresh Token

- **Duração**: 7 dias
- **Uso**: Apenas para renovar access token
- **Armazenamento**: Hash no banco de dados
- **Revogação**: Pode ser revogado imediatamente
- **Conteúdo**: userId, tokenId (jti)

### Blacklist

- **Uso**: Tokens revogados antes de expirar
- **Limpeza**: Tokens expirados são removidos automaticamente
- **Performance**: Índice para consultas rápidas

## 📝 Configuração

### Variáveis de Ambiente (.env)

```env
# JWT Secret
JWT_SECRET_KEY=your-secret-key-here

# Access Token (padrão: 15 minutos)
JWT_ACCESS_TOKEN_EXPIRATION_MINUTES=15

# Refresh Token (padrão: 7 dias)
JWT_REFRESH_TOKEN_EXPIRATION_DAYS=7
```

## 🚀 Como Usar

### 1. Rodar Migrations

```bash
# Via dbmate ou seu sistema de migrations
dart run dbmate up
```

### 2. Instalar Dependências

```bash
cd server
dart pub get
```

### 3. Configurar .env

```bash
cp .env.example .env
# Editar .env com suas configurações
```

### 4. Testar

```bash
# Login
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "teste@terafy.app.br", "password": "senha123"}'

# Usar access token
curl -X GET http://localhost:8080/therapists/me \
  -H "Authorization: Bearer <access_token>"

# Renovar token
curl -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "<refresh_token>"}'

# Logout
curl -X POST http://localhost:8080/auth/logout \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "<refresh_token>"}'
```

## 🔧 Manutenção

### Limpeza Automática

Execute periodicamente para limpar tokens expirados:

```dart
// Refresh tokens expirados
await refreshTokenRepository.deleteExpiredTokens();

// Tokens na blacklist expirados
await blacklistRepository.deleteExpiredTokens();
```

### Monitoramento

- Verificar tamanho da tabela `refresh_tokens`
- Verificar tamanho da tabela `token_blacklist`
- Monitorar taxa de refresh tokens

## 📊 Vantagens

1. **Segurança**: Access tokens curtos (15min) reduzem janela de ataque
2. **Revogação**: Tokens podem ser revogados imediatamente
3. **Performance**: Blacklist consultada apenas quando necessário
4. **Escalabilidade**: Funciona com múltiplos servidores (sem Redis)
5. **UX**: Usuário não precisa fazer login frequentemente

## ⚠️ Próximos Passos

1. **Rodar migrations**: `dart run dbmate up`
2. **Instalar uuid**: `dart pub get` (já adicionado ao pubspec.yaml)
3. **Testar fluxo completo**: Login → Usar token → Renovar → Logout
4. **Implementar no frontend**: Interceptor para renovar token automaticamente

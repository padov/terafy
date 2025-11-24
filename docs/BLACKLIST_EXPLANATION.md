# Como Funciona a Blacklist: Token vs Usuário

## 🔑 Resposta Direta

**A blacklist limita o uso de TOKENS específicos, não do usuário.**

Cada token tem um **JTI (JWT ID)** único. Quando você faz logout, apenas **aquele token específico** é adicionado à blacklist. O usuário pode fazer login novamente e obter novos tokens normalmente.

## 📊 Como Funciona

### Estrutura da Blacklist

```sql
CREATE TABLE token_blacklist (
    token_id VARCHAR(255) PRIMARY KEY,  -- JTI único do token
    user_id INTEGER,                     -- Apenas para referência/auditoria
    expires_at TIMESTAMPTZ,              -- Quando o token expiraria
    revoked_at TIMESTAMPTZ,              -- Quando foi revogado
    reason VARCHAR(100)                  -- Motivo (logout, security, etc.)
);
```

### Verificação no Middleware

```dart
// Extrai o JTI do token
final jti = claims['jti'] as String?;  // Ex: "a1b2c3d4-e5f6-..."

// Verifica se ESTE token específico está na blacklist
final isBlacklisted = await blacklistRepository.isBlacklisted(jti);

if (isBlacklisted) {
  return Response(401, body: '{"error": "Token revogado"}');
}
```

## 💡 Exemplos Práticos

### Cenário 1: Logout Normal

```
1. Usuário faz login → Recebe Token A (JTI: "abc123")
2. Usuário usa Token A em várias requisições ✅
3. Usuário faz logout → Token A adicionado à blacklist
4. Tentativa de usar Token A → ❌ "Token revogado"
5. Usuário faz login novamente → Recebe Token B (JTI: "xyz789")
6. Usuário usa Token B → ✅ Funciona normalmente
```

### Cenário 2: Múltiplos Dispositivos

```
Dispositivo 1:
- Login → Token A (JTI: "token-device-1")
- Usa Token A → ✅ Funciona

Dispositivo 2:
- Login → Token B (JTI: "token-device-2")
- Usa Token B → ✅ Funciona

Logout no Dispositivo 1:
- Token A → ❌ Adicionado à blacklist
- Token B → ✅ Continua funcionando (não foi revogado)

Dispositivo 1 tenta usar Token A:
- ❌ "Token revogado"

Dispositivo 2 continua usando Token B:
- ✅ Funciona normalmente
```

### Cenário 3: Token Roubado

```
1. Token A (JTI: "abc123") é roubado
2. Você detecta e faz logout → Token A na blacklist
3. Atacante tenta usar Token A → ❌ "Token revogado"
4. Você faz login novamente → Token B (JTI: "xyz789")
5. Você usa Token B → ✅ Funciona normalmente
```

## 🔍 Diferença: Token vs Usuário

### Blacklist de Token (Atual) ✅

```dart
// Cada token tem JTI único
Token A: JTI = "abc123" → Blacklist: "abc123"
Token B: JTI = "xyz789" → Blacklist: (não está)

// Verificação
isBlacklisted("abc123") → true  ❌
isBlacklisted("xyz789") → false ✅
```

**Vantagens:**
- ✅ Granular: revoga apenas tokens específicos
- ✅ Múltiplos dispositivos funcionam independentemente
- ✅ Usuário pode fazer login novamente normalmente

### Blacklist de Usuário (Não implementado)

```dart
// Bloqueia TODOS os tokens de um usuário
blacklistUser(userId: 1) → Todos os tokens do user 1 bloqueados

// Verificação
isUserBlacklisted(userId: 1) → true  ❌ Todos os tokens bloqueados
```

**Desvantagens:**
- ❌ Bloqueia usuário completamente
- ❌ Não permite múltiplos dispositivos
- ❌ Mais complexo de gerenciar

## 📝 Implementação Atual

### No Logout:

```dart
// 1. Revoga refresh token específico
await refreshTokenRepository.revokeToken(tokenId);

// 2. Adiciona access token específico à blacklist
await blacklistRepository.addToBlacklist(
  tokenId: jti,        // ← JTI único deste token
  userId: userId,     // ← Apenas para referência
  expiresAt: expiresAt,
  reason: 'logout',
);
```

### Na Verificação:

```dart
// Verifica se ESTE token específico está na blacklist
final jti = claims['jti'] as String?;  // JTI único do token
final isBlacklisted = await blacklistRepository.isBlacklisted(jti);

// Se está na blacklist, bloqueia
// Se não está, permite (mesmo que seja do mesmo usuário)
```

## 🎯 Casos de Uso

### 1. Logout Normal
- **Ação**: Adiciona token atual à blacklist
- **Resultado**: Apenas aquele token é bloqueado
- **Usuário pode**: Fazer login novamente normalmente

### 2. Logout de Todos os Dispositivos
- **Ação**: Revoga todos os refresh tokens do usuário
- **Resultado**: Todos os tokens futuros são bloqueados
- **Usuário precisa**: Fazer login novamente em todos os dispositivos

### 3. Token Roubado
- **Ação**: Adiciona token roubado à blacklist
- **Resultado**: Token roubado não funciona mais
- **Usuário pode**: Fazer login e obter novo token

## 🔄 Fluxo Completo

```
┌─────────────────────────────────────────────────────────┐
│ 1. Login                                                │
│    → Access Token A (JTI: "abc123")                    │
│    → Refresh Token X (ID: "uuid-1")                     │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Usar Token A                                         │
│    GET /therapists/me                                   │
│    Authorization: Bearer Token A                        │
│    → Middleware verifica blacklist                      │
│    → isBlacklisted("abc123")? → false ✅                │
│    → Permite acesso                                     │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Logout                                               │
│    POST /auth/logout                                    │
│    → Adiciona Token A à blacklist                       │
│    → token_blacklist: {token_id: "abc123", ...}         │
│    → Revoga Refresh Token X                            │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Tentar usar Token A novamente                        │
│    GET /therapists/me                                   │
│    Authorization: Bearer Token A                        │
│    → Middleware verifica blacklist                      │
│    → isBlacklisted("abc123")? → true ❌                 │
│    → Retorna 401 "Token revogado"                      │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 5. Novo Login                                           │
│    POST /auth/login                                     │
│    → Access Token B (JTI: "xyz789") ← NOVO             │
│    → Refresh Token Y (ID: "uuid-2") ← NOVO              │
│    → Token B NÃO está na blacklist                     │
│    → Usa Token B normalmente ✅                         │
└─────────────────────────────────────────────────────────┘
```

## 📊 Tabela Comparativa

| Aspecto | Blacklist de Token | Blacklist de Usuário |
|---------|-------------------|---------------------|
| **Granularidade** | Token específico | Todos os tokens do usuário |
| **Múltiplos dispositivos** | ✅ Cada um independente | ❌ Todos bloqueados |
| **Novo login** | ✅ Funciona normalmente | ❌ Bloqueado |
| **Uso** | Logout, token roubado | Suspensão de conta |
| **Implementação** | ✅ Atual | Não implementado |

## ✅ Conclusão

**A blacklist atual limita TOKENS específicos, não usuários.**

- Cada token tem um JTI único
- Apenas tokens específicos são bloqueados
- Usuário pode fazer login e obter novos tokens
- Múltiplos dispositivos funcionam independentemente

**Se precisar bloquear um usuário completamente**, você deve:
1. Mudar `status` do usuário para `'suspended'` ou `'canceled'`
2. Isso será verificado no login e no refresh token
3. Todos os tokens futuros serão bloqueados


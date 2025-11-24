# Resumo da Implementação RLS

## ✅ O que foi implementado

### 1. Migration do Banco de Dados
- **Arquivo**: `server/db/migrations/20251104000000_enable_rls_therapists.sql`
- **Conteúdo**:
  - Habilita RLS na tabela `therapists`
  - Cria 3 policies:
    - `therapist_own_data_policy`: Therapists só veem/modificam seus próprios dados
    - `admin_all_data_policy`: Admins podem ver/modificar tudo
    - `therapist_create_policy`: Permite criação inicial sem user_id

### 2. Helper RLS (`rls_context.dart`)
- **Arquivo**: `server/lib/core/database/rls_context.dart`
- **Função**: Define variáveis de sessão do PostgreSQL antes das queries
- **Métodos**:
  - `setContext()`: Define `app.user_id`, `app.user_role`, `app.account_id`
  - `clearContext()`: Limpa contexto (para admin bypass)

### 3. Repository Modificado
- **Arquivo**: `server/lib/features/therapist/therapist.repository.dart`
- **Mudanças**:
  - Todos os métodos agora aceitam parâmetros opcionais de contexto RLS
  - `getAllTherapists()`: Aceita `userId`, `userRole`, `bypassRLS`
  - `getTherapistById()`: Aceita contexto RLS
  - `createTherapist()`: Aceita contexto RLS para policy de criação
  - `updateTherapist()`: Aceita contexto RLS
  - `deleteTherapist()`: Aceita contexto RLS

### 4. Controller Modificado
- **Arquivo**: `server/lib/features/therapist/therapist.controller.dart`
- **Mudanças**:
  - Todos os métodos passam contexto RLS para o repository
  - `getAllTherapists()`: Passa contexto e `bypassRLS` para admin
  - `getTherapistById()`: Passa contexto RLS
  - `createTherapist()`: Passa `userRole` para contexto RLS
  - `updateTherapist()`: Passa contexto RLS
  - `deleteTherapist()`: Passa contexto RLS

### 5. Handler Modificado
- **Arquivo**: `server/lib/features/therapist/therapist.handler.dart`
- **Mudanças**:
  - Todos os handlers extraem informações do token (`userId`, `userRole`, `accountId`)
  - Passam contexto para o controller
  - Admin usa `bypassRLS: true` para ver todos

## 🔄 Fluxo Completo

```
1. Request → authMiddleware() extrai token JWT
2. Handler extrai userId, userRole, accountId do request
3. Handler chama Controller passando contexto
4. Controller chama Repository passando contexto
5. Repository usa RLSContext.setContext() antes da query
6. PostgreSQL aplica policies RLS automaticamente
7. Retorna apenas dados permitidos
```

## 🛡️ Segurança em Camadas

### Camada 1: Middleware (`authMiddleware`)
- Valida token JWT
- Extrai informações do token
- Adiciona headers ao request

### Camada 2: Authorization Middleware (`requireRole`, `checkResourceAccess`)
- Verifica role do usuário
- Controla acesso a rotas
- Verifica propriedade de recursos

### Camada 3: RLS (Row Level Security)
- **No banco de dados**
- Filtra dados automaticamente
- Protege mesmo se alguém acessar o banco diretamente

## 📝 Exemplo de Uso

### Handler:
```dart
Future<Response> handleGetById(Request request, String id) async {
  // Extrai contexto do token
  final userId = getUserId(request);
  final userRole = getUserRole(request);
  final accountId = getAccountId(request);
  
  // Passa para controller
  final therapist = await _controller.getTherapistById(
    therapistId,
    userId: userId,
    userRole: userRole,
    accountId: accountId,
    bypassRLS: userRole == 'admin', // Admin vê todos
  );
}
```

### Repository:
```dart
Future<Therapist?> getTherapistById(int id, {
  int? userId,
  String? userRole,
  int? accountId,
  bool bypassRLS = false,
}) async {
  final conn = await _dbConnection.getConnection();
  
  // Define contexto RLS
  if (bypassRLS) {
    await RLSContext.clearContext(conn); // Admin
  } else if (userId != null) {
    await RLSContext.setContext(
      conn: conn,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
    );
  }
  
  // Query normal - RLS filtra automaticamente!
  final results = await conn.execute(...);
}
```

## 🎯 Benefícios

1. **Segurança em múltiplas camadas**: Middleware + Authorization + RLS
2. **Proteção no banco**: Mesmo acesso direto ao banco respeita RLS
3. **Menos código**: Não precisa adicionar `WHERE user_id = X` em todas as queries
4. **Automático**: Todas as queries respeitam policies automaticamente
5. **Consistência**: Garante que nenhum dado vaze por erro de código

## ⚠️ Próximos Passos

1. **Rodar migration**: `dart run dbmate up` (ou seu comando de migration)
2. **Testar**: Verificar que therapists só veem seus próprios dados
3. **Testar admin**: Verificar que admin vê todos
4. **Monitorar**: Verificar logs e performance

## 📚 Documentação

- `docs/RLS_IN_DART.md`: Guia completo de como usar RLS no Dart
- `server/lib/features/therapist/therapist.repository.rls_example.dart`: Exemplos práticos


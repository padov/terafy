# Como Usar RLS (Row Level Security) no Dart

## 📋 Visão Geral

O RLS (Row Level Security) do PostgreSQL permite que o banco de dados filtre automaticamente os dados baseado em policies. No Dart, você precisa definir **variáveis de sessão** antes das queries para que o PostgreSQL aplique as policies.

## 🔑 Conceito Principal

### Como funciona:

1. **No PostgreSQL**: Você cria policies que verificam variáveis de sessão
   ```sql
   CREATE POLICY therapist_policy ON therapists
     USING (user_id = current_setting('app.user_id', true)::int);
   ```

2. **No Dart**: Você define essas variáveis antes das queries
   ```dart
   await conn.execute("SET LOCAL app.user_id = '1'");
   // Agora todas as queries respeitam o RLS automaticamente
   ```

## 🛠️ Implementação

### 1. Criar Helper RLS (`rls_context.dart`)

```dart
class RLSContext {
  static Future<void> setContext({
    required Connection conn,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    await conn.execute(
      Sql.named("SET LOCAL app.user_id = @user_id"),
      parameters: {'user_id': userId.toString()},
    );
    // ... outras variáveis
  }
}
```

### 2. Usar no Repository

#### Antes (sem RLS):
```dart
Future<Therapist?> getTherapistById(int id) async {
  final conn = await _dbConnection.getConnection();
  final results = await conn.execute(
    Sql.named('SELECT * FROM therapists WHERE id = @id'),
    parameters: {'id': id},
  );
  // ...
}
```

#### Depois (com RLS):
```dart
Future<Therapist?> getTherapistById(int id, {int? userId, String? userRole}) async {
  final conn = await _dbConnection.getConnection();
  
  // Define contexto RLS antes da query
  if (userId != null) {
    await RLSContext.setContext(
      conn: conn,
      userId: userId,
      userRole: userRole,
    );
  }
  
  final results = await conn.execute(
    Sql.named('SELECT * FROM therapists WHERE id = @id'),
    parameters: {'id': id},
  );
  // O PostgreSQL aplica o RLS automaticamente!
  // ...
}
```

### 3. Passar Contexto do Handler

No handler, extrair informações do request e passar para o repository:

```dart
Future<Response> handleGetById(Request request, String id) async {
  final userId = getUserId(request);
  final userRole = getUserRole(request);
  final accountId = getAccountId(request);
  
  final therapist = await _controller.getTherapistById(
    int.parse(id),
    userId: userId,
    userRole: userRole,
    accountId: accountId,
  );
  // ...
}
```

## 📝 Exemplo Completo

### Repository com RLS:

```dart
class TherapistRepository {
  final DBConnection _dbConnection;

  Future<Therapist?> getTherapistById(
    int id, {
    int? userId,
    String? userRole,
    int? accountId,
  }) async {
    final conn = await _dbConnection.getConnection();
    
    // Define contexto RLS se userId fornecido
    if (userId != null) {
      await RLSContext.setContext(
        conn: conn,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );
    }
    
    // Query normal - o RLS filtra automaticamente!
    final results = await conn.execute(
      Sql.named('''
        SELECT * FROM therapists WHERE id = @id
      '''),
      parameters: {'id': id},
    );
    
    // Se não encontrou, pode ser porque o RLS bloqueou
    if (results.isEmpty) {
      return null;
    }
    
    return Therapist.fromMap(results.first.toColumnMap());
  }
}
```

### Controller passando contexto:

```dart
class TherapistController {
  Future<Therapist> getTherapistById(
    int id, {
    int? userId,
    String? userRole,
    int? accountId,
  }) async {
    final therapist = await _repository.getTherapistById(
      id,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
    );
    
    if (therapist == null) {
      throw TherapistException('Terapeuta não encontrado', 404);
    }
    
    return therapist;
  }
}
```

### Handler extraindo do request:

```dart
Future<Response> handleGetById(Request request, String id) async {
  final therapistId = int.tryParse(id);
  if (therapistId == null) {
    return badRequestResponse('ID inválido');
  }

  // Extrai informações do token (já no middleware)
  final userId = getUserId(request);
  final userRole = getUserRole(request);
  final accountId = getAccountId(request);

  final therapist = await _controller.getTherapistById(
    therapistId,
    userId: userId,
    userRole: userRole,
    accountId: accountId,
  );
  
  return successResponse(therapist.toJson());
}
```

## ⚠️ Pontos Importantes

### 1. `SET LOCAL` vs `SET`

- **`SET LOCAL`**: Variável válida apenas na transação atual
- **`SET`**: Variável válida para toda a sessão

**Recomendação**: Use `SET LOCAL` para segurança (variável é limpa após commit/rollback)

### 2. Queries Administrativas

Para queries que precisam ignorar o RLS (ex: admin buscando todos):

```dart
Future<List<Therapist>> getAllTherapists({bool bypassRLS = false}) async {
  final conn = await _dbConnection.getConnection();
  
  if (!bypassRLS) {
    // Define contexto normal
    await RLSContext.setContext(conn: conn, userId: userId);
  } else {
    // Limpa contexto para admin
    await RLSContext.clearContext(conn);
  }
  
  // Query...
}
```

### 3. Performance

- O RLS adiciona um pequeno overhead (verificação de policies)
- Use índices adequados nas colunas usadas nas policies
- Considere usar `SET` em vez de `SET LOCAL` se fizer muitas queries na mesma sessão

## 🔄 Fluxo Completo

```
1. Request chega → authMiddleware() extrai token
2. Handler recebe request com headers (x-user-id, x-user-role, x-account-id)
3. Handler chama Controller passando userId, userRole, accountId
4. Controller chama Repository passando contexto
5. Repository define variáveis de sessão (SET LOCAL app.user_id = X)
6. Repository executa query
7. PostgreSQL aplica policies RLS automaticamente
8. Retorna apenas dados permitidos
```

## 🎯 Vantagens do RLS

1. **Segurança em múltiplas camadas**: Middleware + RLS
2. **Proteção mesmo se alguém acessar o banco diretamente**
3. **Menos código**: Não precisa adicionar `WHERE user_id = X` em todas as queries
4. **Consistência**: Todas as queries respeitam automaticamente

## 📚 Próximos Passos

1. Criar migration para habilitar RLS na tabela `therapists`
2. Criar policies no PostgreSQL
3. Modificar repositories para usar `RLSContext`
4. Testar com diferentes usuários


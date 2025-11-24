# Por que ENUMs do PostgreSQL retornam UndecodedBytes?

## O Problema

O pacote `postgres` do Dart não decodifica automaticamente os valores ENUM do PostgreSQL para strings. Em vez disso, retorna como `UndecodedBytes`, que é um tipo especial que contém os bytes não decodificados.

Isso acontece porque:
1. PostgreSQL armazena ENUMs como tipos customizados (OID específico)
2. O driver `postgres` não tem mapeamento automático para esses tipos
3. Os valores são retornados como `UndecodedBytes` até serem explicitamente convertidos

## Soluções

### Solução 1: Converter no SQL (RECOMENDADO) ✅

Fazer CAST no SQL para converter ENUM para TEXT antes de retornar:

```dart
// Exemplo no repository
final results = await conn.execute(
  Sql.named('''
    SELECT 
      id,
      email,
      password_hash,
      role::text,
      account_type::text,
      status::text,
      ...
    FROM users 
    WHERE email = @email
  '''),
  parameters: {'email': email},
);
```

**Vantagens:**
- ✅ Converte no banco (mais eficiente)
- ✅ Não precisa tratar no código Dart
- ✅ Funciona consistentemente

### Solução 2: Converter no Código Dart (ATUAL)

Converter `UndecodedBytes` para String no modelo:

```dart
// No User.fromMap()
role: map['role']?.toString() ?? 'therapist',
status: map['status']?.toString() ?? 'active',
```

**Vantagens:**
- ✅ Funciona sem mudar queries
- ✅ Fallback para valores null

**Desvantagens:**
- ❌ Depende de `toString()` funcionar corretamente
- ❌ Menos eficiente (conversão no código)

### Solução 3: Converter UndecodedBytes explicitamente

Se `toString()` não funcionar, pode converter manualmente:

```dart
static String _parseEnum(dynamic value) {
  if (value == null) return 'therapist';
  if (value is String) return value;
  if (value is UndecodedBytes) {
    return String.fromCharCodes(value.bytes);
  }
  return value.toString();
}
```

## Recomendação

**Use a Solução 1 (CAST no SQL)** para melhor performance e código mais limpo.

Exemplo completo:
```dart
Future<User?> getUserByEmail(String email) async {
  final conn = await _dbConnection.getConnection();
  final results = await conn.execute(
    Sql.named('''
      SELECT 
        id,
        email,
        password_hash,
        role::text as role,
        account_type::text as account_type,
        account_id,
        status::text as status,
        last_login_at,
        email_verified,
        created_at,
        updated_at
      FROM users 
      WHERE email = @email
    '''),
    parameters: {'email': email},
  );

  if (results.isEmpty) {
    return null;
  }

  final map = results.first.toColumnMap();
  return User.fromMap(map);
}
```

Dessa forma, os campos ENUM já vêm como String do banco e não precisam de tratamento especial no código Dart.


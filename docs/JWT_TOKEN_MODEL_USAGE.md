# Como Usar o Model JwtToken

## 📋 Visão Geral

O `JwtToken` é um model tipado que representa os claims de um token JWT, fornecendo acesso seguro e métodos auxiliares úteis.

## 🚀 Uso Básico

### 1. Validar e Parsear Token

```dart
import 'package:common/common.dart';
import 'package:server/core/services/jwt_token_helper.dart';

// Valida e parseia o token
final jwtToken = JwtTokenHelper.validateAndParse(tokenString);

if (jwtToken == null) {
  // Token inválido ou expirado
  return Response(401, body: 'Token inválido');
}

// Usa o token tipado
print('User ID: ${jwtToken.userId}');
print('Email: ${jwtToken.email}');
print('Role: ${jwtToken.role}');
```

### 2. Criar a partir de Claims (Map)

```dart
import 'package:common/common.dart';
import 'package:server/core/services/jwt_service.dart';

// Decodifica token
final claims = JwtService.validateToken(token);
if (claims == null) {
  return Response(401);
}

// Cria model a partir dos claims
final jwtToken = JwtToken.fromMap(claims);

// Agora tem acesso tipado
final userId = jwtToken.userId; // int
final email = jwtToken.email;   // String
```

## 🔍 Propriedades Disponíveis

### Informações do Usuário
```dart
jwtToken.userId        // int - ID do usuário
jwtToken.email        // String - Email do usuário
jwtToken.role         // String - Role ('therapist', 'patient', 'admin')
```

### Informações da Conta
```dart
jwtToken.accountType  // String? - Tipo da conta ('therapist' ou 'patient')
jwtToken.accountId   // int? - ID da conta vinculada
jwtToken.hasAccount  // bool - Se tem conta vinculada
```

### Informações de Tempo
```dart
jwtToken.issuedAt           // int - Timestamp de emissão (Unix)
jwtToken.expiration         // int - Timestamp de expiração (Unix)
jwtToken.issuedAtDateTime   // DateTime - Data de emissão
jwtToken.expirationDateTime // DateTime - Data de expiração
jwtToken.isExpired          // bool - Se está expirado
jwtToken.timeUntilExpiration // Duration - Tempo restante
```

### Helpers de Role
```dart
jwtToken.isTherapist  // bool - Se é terapeuta
jwtToken.isPatient    // bool - Se é paciente
jwtToken.isAdmin      // bool - Se é admin
```

### Helpers de Conta
```dart
jwtToken.hasTherapistAccount // bool - Se tem conta de terapeuta
jwtToken.hasPatientAccount   // bool - Se tem conta de paciente
jwtToken.therapistId         // int? - ID do therapist (se tiver)
jwtToken.patientId          // int? - ID do patient (se tiver)
```

## 💡 Exemplos Práticos

### Exemplo 1: Verificar se usuário é admin

```dart
final jwtToken = JwtTokenHelper.validateAndParse(token);
if (jwtToken == null) {
  return Response(401);
}

if (jwtToken.isAdmin) {
  // Usuário é admin
  return await handleAdminRequest(request);
} else {
  return Response(403, body: 'Acesso negado');
}
```

### Exemplo 2: Verificar se tem perfil de terapeuta

```dart
final jwtToken = JwtTokenHelper.validateAndParse(token);
if (jwtToken == null || !jwtToken.hasTherapistAccount) {
  return Response(400, body: 'Usuário não possui perfil de terapeuta');
}

final therapistId = jwtToken.therapistId!; // Garantido que não é null
// Usa therapistId...
```

### Exemplo 3: Verificar expiração

```dart
final jwtToken = JwtTokenHelper.validateAndParse(token);
if (jwtToken == null) {
  return Response(401);
}

if (jwtToken.isExpired) {
  return Response(401, body: 'Token expirado');
}

// Verifica tempo restante
if (jwtToken.timeUntilExpiration.inHours < 1) {
  // Token vai expirar em menos de 1 hora
  // Pode retornar um novo token ou avisar o cliente
}
```

### Exemplo 4: Usar no Middleware

```dart
// No auth_middleware.dart
final claims = JwtService.validateToken(token);
if (claims == null) {
  return Response(401);
}

// Cria model para facilitar acesso
final jwtToken = JwtToken.fromMap(claims);

// Adiciona ao request usando o model
final updatedRequest = request.change(
  headers: {
    ...request.headers,
    'x-user-id': jwtToken.userIdString,
    'x-user-role': jwtToken.role,
    'x-account-type': jwtToken.accountType ?? '',
    'x-account-id': jwtToken.accountId?.toString() ?? '',
  },
);
```

### Exemplo 5: Serialização

```dart
// Converter para Map
final map = jwtToken.toMap();
// ou
final json = jwtToken.toJson();

// Converter para String (usando toString)
print(jwtToken.toString());
// Output: JwtToken(userId: 1, email: user@example.com, ...)
```

## 🔄 Migração de Código Existente

### Antes (usando Map):
```dart
final claims = JwtService.validateToken(token);
if (claims == null) return Response(401);

final userId = int.parse(claims['sub'] as String);
final role = claims['role'] as String;
final accountId = claims['account_id'] as int?;
```

### Depois (usando Model):
```dart
final jwtToken = JwtTokenHelper.validateAndParse(token);
if (jwtToken == null) return Response(401);

final userId = jwtToken.userId;      // Já é int!
final role = jwtToken.role;          // Já é String!
final accountId = jwtToken.accountId; // Já é int?
```

## ✅ Vantagens do Model

1. **Type Safety**: Acesso tipado, sem casts manuais
2. **Menos Erros**: Compilador detecta erros de tipo
3. **Código Limpo**: Métodos auxiliares úteis (`isExpired`, `hasAccount`, etc.)
4. **Documentação**: Propriedades bem documentadas
5. **Reutilizável**: Pode ser usado tanto no backend quanto no frontend

## 📚 API Completa

### Construtores
- `JwtToken(...)` - Construtor direto
- `JwtToken.fromMap(Map<String, dynamic>)` - Factory a partir de claims

### Métodos
- `toMap()` - Converte para Map
- `toJson()` - Alias para toMap()
- `toString()` - Representação em string

### Getters
- `userId`, `email`, `role` - Informações básicas
- `accountType`, `accountId` - Informações da conta
- `issuedAt`, `expiration` - Timestamps
- `issuedAtDateTime`, `expirationDateTime` - Datas
- `isExpired`, `timeUntilExpiration` - Status de expiração
- `hasAccount`, `hasTherapistAccount`, `hasPatientAccount` - Status da conta
- `isTherapist`, `isPatient`, `isAdmin` - Verificações de role
- `therapistId`, `patientId` - IDs específicos

## 🔧 Helper Functions

### JwtTokenHelper

```dart
// Valida e parseia (recomendado)
final jwtToken = JwtTokenHelper.validateAndParse(token);

// Decodifica sem validar (apenas para debug)
final jwtToken = JwtTokenHelper.decode(token);
```


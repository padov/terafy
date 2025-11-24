# Middleware de Autenticação e Autorização

## Visão Geral

O sistema de middleware fornece autenticação e autorização para as rotas da API. As rotas públicas são permitidas sem token, enquanto as rotas protegidas requerem um token JWT válido.

## Rotas Públicas

As seguintes rotas NÃO requerem autenticação:
- `/ping` - Health check
- `/auth/login` - Login de usuário
- `/auth/register` - Registro de novo usuário

## Middlewares Disponíveis

### 1. `authMiddleware()`
Middleware principal que valida tokens JWT e adiciona informações do usuário ao request.

**Uso:** Já aplicado globalmente no `server.dart`

### 2. `requireRole(String requiredRole)`
Verifica se o usuário tem uma role específica.

**Exemplo:**
```dart
router.get('/admin-only', requireRole('admin').call((request) async {
  // Apenas admins podem acessar
  return Response.ok('Admin content');
}));
```

### 3. `requireAnyRole(List<String> allowedRoles)`
Verifica se o usuário tem uma das roles permitidas.

**Exemplo:**
```dart
router.get('/therapist-or-admin', requireAnyRole(['therapist', 'admin']).call((request) async {
  // Terapeutas ou admins podem acessar
  return Response.ok('Protected content');
}));
```

### 4. `requireAuth()`
Verifica se o usuário está autenticado (útil para rotas específicas dentro de handlers).

**Exemplo:**
```dart
router.get('/profile', requireAuth().call((request) async {
  final userId = getUserId(request);
  // Usuário autenticado pode acessar
  return Response.ok('Profile for user $userId');
}));
```

## Funções Auxiliares

### `getUserId(Request request)`
Extrai o ID do usuário autenticado do request.

```dart
final userId = getUserId(request);
if (userId == null) {
  return Response(401, body: '{"error": "Não autenticado"}');
}
```

### `getUserRole(Request request)`
Extrai a role do usuário autenticado.

```dart
final role = getUserRole(request);
if (role != 'admin') {
  return Response(403, body: '{"error": "Acesso negado"}');
}
```

### `getAccountType(Request request)`
Extrai o tipo de conta (therapist, patient).

```dart
final accountType = getAccountType(request);
```

### `getAccountId(Request request)`
Extrai o ID da conta vinculada (ID do therapist ou patient).

```dart
final accountId = getAccountId(request);
```

## Exemplo de Uso no Handler

```dart
import 'package:server/core/middleware/auth_middleware.dart';

class TherapistHandler {
  Router get router {
    final router = Router();
    
    // GET /therapists - Lista todos os terapeutas (requer autenticação)
    router.get('/', (Request request) async {
      final userId = getUserId(request);
      final role = getUserRole(request);
      
      // Só terapeutas podem ver a lista completa
      if (role != 'therapist' && role != 'admin') {
        return Response(
          403,
          body: '{"error": "Acesso negado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Lógica do handler...
      return Response.ok('Lista de terapeutas');
    });
    
    // GET /therapists/<id> - Ver perfil específico (requer autenticação)
    router.get('/<id>', (Request request, String id) async {
      final userId = getUserId(request);
      final therapistId = int.tryParse(id);
      
      if (therapistId == null) {
        return Response.badRequest(body: '{"error": "ID inválido"}');
      }
      
      // Verifica se o usuário está vendo seu próprio perfil ou é admin
      final role = getUserRole(request);
      final accountId = getAccountId(request);
      
      if (role != 'admin' && accountId != therapistId) {
        return Response(
          403,
          body: '{"error": "Acesso negado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Lógica do handler...
      return Response.ok('Perfil do terapeuta $therapistId');
    });
    
    return router;
  }
}
```

## Como Testar

### 1. Testar rota pública (sem token):
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "teste@terafy.com", "password": "senha123"}'
```

### 2. Testar rota protegida (sem token):
```bash
curl -X GET http://localhost:8080/therapists
# Deve retornar 401 Unauthorized
```

### 3. Testar rota protegida (com token):
```bash
# Primeiro, faça login para obter o token
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "teste@terafy.com", "password": "senha123"}' | jq -r '.auth_token')

# Depois, use o token nas requisições
curl -X GET http://localhost:8080/therapists \
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting

### Erro: "Token não fornecido"
- Verifique se o header `Authorization: Bearer <token>` está sendo enviado
- Verifique se o token não está expirado

### Erro: "Token inválido ou expirado"
- O token pode ter expirado (padrão: 7 dias)
- Faça login novamente para obter um novo token

### Erro: "Acesso negado"
- Verifique se o usuário tem a role necessária
- Verifique se está tentando acessar recurso de outro usuário (sem ser admin)


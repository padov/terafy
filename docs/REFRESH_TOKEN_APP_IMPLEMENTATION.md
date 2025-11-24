# Implementação de Refresh Token no App Flutter

## 📋 Visão Geral

Este documento descreve o planejamento completo para implementar o mecanismo de Refresh Token no app Flutter, permitindo renovação automática de tokens de acesso sem necessidade de novo login.

## 🎯 Objetivos

1. **Renovação Automática**: Renovar access tokens automaticamente quando expirarem
2. **Experiência do Usuário**: Evitar logout forçado por token expirado
3. **Segurança**: Manter tokens de curta duração (15 min) com refresh tokens de longa duração (7 dias)
4. **Sincronização**: Alinhar com a implementação do backend

## 📊 Estado Atual

### ✅ O que já existe:
- Backend retorna `auth_token` e `refresh_token` no login/register
- `AuthResultModel` já possui campo `refreshAuthToken`
- `SecureStorageService` existe para armazenamento seguro
- `AuthInterceptor` detecta erros 401

### ❌ O que falta:
- Salvar `refresh_token` no storage
- Endpoint para refresh token no `AuthRemoteDataSource`
- Lógica de renovação automática no `AuthInterceptor`
- Use case para refresh token
- Logout que revoga refresh token

## 🏗️ Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │ AuthBloc     │───▶│ RefreshToken │───▶│ SecureStorage│ │
│  │              │    │ UseCase      │    │ Service      │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                      │                             │
│         │                      ▼                             │
│         │            ┌──────────────┐                         │
│         └──────────▶│ AuthRemote  │                         │
│                      │ DataSource  │                         │
│                      └──────────────┘                         │
│                             │                                 │
│                             ▼                                 │
│  ┌──────────────────────────────────────────────┐           │
│  │         AuthInterceptor (Dio)                 │           │
│  │  - Detecta 401                                │           │
│  │  - Tenta refresh automático                   │           │
│  │  - Retry da requisição original               │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Plano de Implementação

### **Fase 1: Infraestrutura de Storage** ✅

#### 1.1 Atualizar `SecureStorageService`
- Adicionar métodos para salvar/recuperar `refresh_token`
- Manter compatibilidade com código existente

**Arquivo**: `app/lib/core/services/secure_storage_service.dart`

```dart
// Adicionar constantes
static const _refreshTokenKey = 'refresh_token';

// Adicionar métodos
Future<void> saveRefreshToken(String token) async {
  await _storage.write(key: _refreshTokenKey, value: token);
}

Future<String?> getRefreshToken() async {
  return await _storage.read(key: _refreshTokenKey);
}

Future<void> deleteRefreshToken() async {
  await _storage.delete(key: _refreshTokenKey);
}

// Atualizar clearAll para incluir refresh_token
Future<void> clearAll() async {
  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _refreshTokenKey);
  await _storage.delete(key: _userIdentifierKey);
}
```

---

### **Fase 2: Data Source** ✅

#### 2.1 Adicionar endpoint de refresh no `AuthRemoteDataSource`

**Arquivo**: `app/lib/core/data/datasources/remote/auth_remote_data_source.dart`

```dart
// Adicionar método abstrato
Future<AuthResultModel> refreshToken(String refreshToken);

// Implementação
@override
Future<AuthResultModel> refreshToken(String refreshToken) async {
  try {
    final response = await dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      // Backend retorna: { "access_token": "...", "refresh_token": "..." }
      // Precisamos adaptar para o formato esperado pelo AuthResultModel
      return AuthResultModel.fromJson({
        'auth_token': response.data['access_token'],
        'refresh_token': response.data['refresh_token'],
      });
    } else {
      throw Exception('Falha ao renovar token');
    }
  } on DioException catch (e) {
    String errorMessage = 'Erro ao renovar token';
    
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 401) {
        errorMessage = responseData?['error'] ?? 'Refresh token inválido ou expirado';
      } else {
        errorMessage = responseData?['error'] ?? 'Erro ao renovar token';
      }
    }
    
    throw Exception(errorMessage);
  }
}
```

---

### **Fase 3: Repository e Use Case** ✅

#### 3.1 Atualizar `AuthRepository`

**Arquivo**: `app/lib/core/domain/repositories/auth_repository.dart`

```dart
// Adicionar método
Future<AuthResult> refreshToken(String refreshToken);
```

#### 3.2 Atualizar `AuthRepositoryImpl`

**Arquivo**: `app/lib/core/data/repositories/auth_repository_impl.dart`

```dart
@override
Future<AuthResult> refreshToken(String refreshToken) {
  return _remoteDataSource.refreshToken(refreshToken);
}
```

#### 3.3 Criar `RefreshTokenUseCase`

**Arquivo**: `app/lib/core/domain/usecases/auth/refresh_token_usecase.dart`

```dart
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository _authRepository;

  RefreshTokenUseCase(this._authRepository);

  Future<AuthResult> call(String refreshToken) async {
    return await _authRepository.refreshToken(refreshToken);
  }
}
```

---

### **Fase 4: Atualizar Login/Register** ✅

#### 4.1 Atualizar `LoginBloc` para salvar refresh token

**Arquivo**: `app/lib/features/login/bloc/login_bloc.dart`

```dart
// No método _onLoginButtonPressed, após sucesso:
final authResult = result.authResult;
if (authResult.authToken != null) {
  await secureStorageService.saveToken(authResult.authToken!);
  
  // NOVO: Salvar refresh token
  if (authResult.refreshAuthToken != null) {
    await secureStorageService.saveRefreshToken(authResult.refreshAuthToken!);
  }
  
  // ... resto do código
}
```

#### 4.2 Atualizar `RegisterBloc` (se existir) da mesma forma

---

### **Fase 5: AuthInterceptor com Refresh Automático** ✅

#### 5.1 Refatorar `AuthInterceptor`

**Arquivo**: `app/lib/core/interceptors/auth_interceptor.dart`

**Estratégia**:
1. Detectar erro 401
2. Tentar obter refresh token do storage
3. Se existir, tentar renovar
4. Se renovação bem-sucedida, retry da requisição original
5. Se falhar, fazer logout

```dart
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final RefreshTokenUseCase? _refreshTokenUseCase;
  final VoidCallback? onTokenExpired;
  final Dio _dio;

  AuthInterceptor(
    this._secureStorage,
    this._dio, {
    this._refreshTokenUseCase,
    this.onTokenExpired,
  });

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ... código existente
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Se o erro for 401 e não for login/refresh
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != '/auth/login' &&
        err.requestOptions.path != '/auth/refresh') {
      
      // Se já está tentando refresh, adiciona à fila
      if (_isRefreshing) {
        _pendingRequests.add(_PendingRequest(
          options: err.requestOptions,
          handler: handler,
        ));
        return;
      }

      // Tenta refresh
      _isRefreshing = true;
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken != null && _refreshTokenUseCase != null) {
        try {
          final result = await _refreshTokenUseCase!.call(refreshToken);
          
          // Salva novos tokens
          if (result.authToken != null) {
            await _secureStorage.saveToken(result.authToken!);
          }
          if (result.refreshAuthToken != null) {
            await _secureStorage.saveRefreshToken(result.refreshAuthToken!);
          }

          // Atualiza header da requisição original
          err.requestOptions.headers['Authorization'] = 
              'Bearer ${result.authToken}';

          // Retry da requisição original
          final response = await _dio.fetch(err.requestOptions);
          
          // Processa requisições pendentes
          _processPendingRequests(result.authToken!);
          
          handler.resolve(response);
          return;
        } catch (e) {
          // Refresh falhou, fazer logout
          await _logout();
          handler.reject(err);
          return;
        } finally {
          _isRefreshing = false;
        }
      } else {
        // Não tem refresh token, fazer logout
        await _logout();
      }
    }

    handler.next(err);
  }

  Future<void> _logout() async {
    await _secureStorage.deleteToken();
    await _secureStorage.deleteRefreshToken();
    await _secureStorage.deleteUserIdentifier();
    onTokenExpired?.call();
    
    if (navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!)
          .pushNamedAndRemoveUntil(AppRouter.loginRoute, (route) => false);
    }
  }

  void _processPendingRequests(String newToken) {
    for (var pending in _pendingRequests) {
      pending.options.headers['Authorization'] = 'Bearer $newToken';
      _dio.fetch(pending.options).then(
        (response) => pending.handler.resolve(response),
        onError: (error) => pending.handler.reject(error),
      );
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}
```

---

### **Fase 6: Logout com Revogação** ✅

#### 6.1 Adicionar endpoint de logout no `AuthRemoteDataSource`

```dart
Future<void> logout({String? refreshToken, String? accessToken});
```

#### 6.2 Implementar logout no `LoginBloc`

```dart
// No método _onLogoutPressed:
try {
  final refreshToken = await secureStorageService.getRefreshToken();
  final accessToken = await secureStorageService.getToken();
  
  // Chama endpoint de logout no backend
  await authRepository.logout(
    refreshToken: refreshToken,
    accessToken: accessToken,
  );
} catch (e) {
  // Log erro, mas continua com logout local
  AppLogger.warning('Erro ao fazer logout no servidor: $e');
} finally {
  // Sempre limpa storage local
  await secureStorageService.clearAll();
  emit(LogoutSuccess());
}
```

---

### **Fase 7: Dependency Injection** ✅

#### 7.1 Atualizar `DependencyContainer`

**Arquivo**: `app/lib/core/dependencies/dependency_container.dart`

```dart
// Adicionar
RefreshTokenUseCase? refreshTokenUseCase;

// No setup():
refreshTokenUseCase = RefreshTokenUseCase(authRepository);

// Atualizar setupAuthInterceptor():
void setupAuthInterceptor({VoidCallback? onTokenExpired}) {
  dio.interceptors.removeWhere(
    (interceptor) => interceptor is AuthInterceptor,
  );

  dio.interceptors.add(
    AuthInterceptor(
      secureStorageService,
      dio, // Passar dio para retry
      refreshTokenUseCase: refreshTokenUseCase,
      onTokenExpired: onTokenExpired,
    ),
  );
}
```

---

## 🔄 Fluxo de Funcionamento

### **Cenário 1: Login Bem-Sucedido**
```
1. Usuário faz login
2. Backend retorna auth_token + refresh_token
3. App salva ambos no SecureStorage
4. App usa auth_token nas requisições
```

### **Cenário 2: Token Expirado (Renovação Automática)**
```
1. Requisição retorna 401
2. AuthInterceptor detecta erro
3. Obtém refresh_token do storage
4. Chama POST /auth/refresh
5. Backend retorna novo access_token + refresh_token
6. App salva novos tokens
7. Retry da requisição original com novo token
8. Requisição bem-sucedida (usuário nem percebe)
```

### **Cenário 3: Refresh Token Expirado**
```
1. Requisição retorna 401
2. AuthInterceptor tenta refresh
3. POST /auth/refresh retorna 401
4. App limpa storage
5. Redireciona para login
```

### **Cenário 4: Logout**
```
1. Usuário clica em logout
2. App chama POST /auth/logout com refresh_token
3. Backend revoga refresh_token e adiciona access_token à blacklist
4. App limpa storage local
5. Redireciona para login
```

---

## 🧪 Testes Necessários

### **Testes Unitários**
- ✅ `RefreshTokenUseCase` deve chamar repository corretamente
- ✅ `SecureStorageService` deve salvar/recuperar refresh_token
- ✅ `AuthInterceptor` deve tentar refresh em 401
- ✅ `AuthInterceptor` deve fazer logout se refresh falhar

### **Testes de Integração**
- ✅ Login salva refresh_token
- ✅ Requisição com token expirado renova automaticamente
- ✅ Múltiplas requisições simultâneas com token expirado (fila)
- ✅ Logout revoga tokens no backend

---

## 📦 Arquivos a Criar/Modificar

### **Novos Arquivos**
1. `app/lib/core/domain/usecases/auth/refresh_token_usecase.dart`
2. `app/lib/core/interceptors/auth_interceptor.dart` (refatorar)

### **Arquivos a Modificar**
1. `app/lib/core/services/secure_storage_service.dart`
2. `app/lib/core/data/datasources/remote/auth_remote_data_source.dart`
3. `app/lib/core/domain/repositories/auth_repository.dart`
4. `app/lib/core/data/repositories/auth_repository_impl.dart`
5. `app/lib/features/login/bloc/login_bloc.dart`
6. `app/lib/core/dependencies/dependency_container.dart`

---

## ⚠️ Considerações Importantes

### **Segurança**
- ✅ Refresh token nunca deve ser exposto em logs
- ✅ Tokens devem ser armazenados apenas em SecureStorage
- ✅ Logout deve sempre revogar tokens no backend

### **Performance**
- ✅ Evitar múltiplas tentativas de refresh simultâneas (fila)
- ✅ Cache do token em memória pode ser considerado (com cuidado)

### **UX**
- ✅ Renovação deve ser transparente para o usuário
- ✅ Loading indicators apenas se necessário
- ✅ Mensagens de erro claras quando refresh falhar

---

## 🚀 Ordem de Implementação Recomendada

1. **Fase 1**: Storage (mais simples, base para tudo)
2. **Fase 2**: Data Source (testável isoladamente)
3. **Fase 3**: Repository e Use Case (lógica de negócio)
4. **Fase 4**: Login/Register (salvar refresh token)
5. **Fase 5**: AuthInterceptor (mais complexo, depende das anteriores)
6. **Fase 6**: Logout (completa o ciclo)
7. **Fase 7**: Dependency Injection (conecta tudo)

---

## 📚 Referências

- [Backend Refresh Token Implementation](./REFRESH_TOKEN_IMPLEMENTATION.md)
- [JWT Token Structure](./JWT_TOKEN_STRUCTURE.md)
- [Dio Interceptors Documentation](https://pub.dev/packages/dio#interceptors)


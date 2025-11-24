# Por que usar UseCase? 🤔

## 📚 O que é UseCase?

**UseCase** (ou **Interactor**) é uma camada da Clean Architecture que representa uma **ação de negócio específica** que o sistema pode executar. É uma abstração que encapsula a lógica de negócio de forma isolada.

## 🎯 Propósito Principal

O UseCase serve como uma **camada intermediária** entre a apresentação (UI/Bloc) e o domínio (Repository), garantindo que:

1. **A lógica de negócio fica isolada** da UI
2. **Facilita testes** (pode mockar o repository facilmente)
3. **Reutilização** da mesma lógica em diferentes lugares
4. **Single Responsibility** - cada UseCase faz uma coisa específica

## 🔍 Exemplo Prático no Projeto

### **Sem UseCase** (acoplado):
```dart
// ❌ Bloc chamando diretamente o Repository
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository; // Acoplado ao Repository
  
  Future<void> _onLogin(LoginEvent event) async {
    // Lógica de negócio misturada com lógica de apresentação
    final result = await repository.login(event.email, event.password);
    // ... tratamento de erro, validações, etc.
  }
}
```

### **Com UseCase** (desacoplado):
```dart
// ✅ Bloc chamando UseCase
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase; // Desacoplado - só conhece a ação
  
  Future<void> _onLogin(LoginEvent event) async {
    // Foca apenas na lógica de apresentação
    final result = await loginUseCase(event.email, event.password);
    // ... tratamento de estado da UI
  }
}

// ✅ UseCase encapsula a lógica de negócio
class LoginUseCase {
  final AuthRepository repository;
  
  Future<AuthResult> call(String email, String password) {
    return repository.login(email, password);
  }
}
```

## 💡 Benefícios Práticos

### 1. **Testabilidade** 🧪

```dart
// Teste do UseCase é simples e isolado
test('LoginUseCase deve chamar repository.login', () async {
  final mockRepository = MockAuthRepository();
  final useCase = LoginUseCase(mockRepository);
  
  await useCase('email@test.com', 'password123');
  
  verify(mockRepository.login('email@test.com', 'password123')).called(1);
});
```

### 2. **Reutilização** ♻️

```dart
// O mesmo UseCase pode ser usado em diferentes lugares:
// - LoginBloc
// - BiometricLoginBloc  
// - AutoLoginService
// - Testes

class LoginBloc {
  final LoginUseCase loginUseCase; // Reutiliza
}

class BiometricLoginBloc {
  final LoginUseCase loginUseCase; // Reutiliza
}
```

### 3. **Lógica de Negócio Complexa** 🧠

Quando a lógica fica mais complexa, o UseCase é essencial:

```dart
// ✅ UseCase com lógica de negócio
class RefreshTokenUseCase {
  final AuthRepository repository;
  final SecureStorageService storage;
  
  Future<AuthResult> call(String refreshToken) async {
    // 1. Valida refresh token
    if (refreshToken.isEmpty) {
      throw Exception('Refresh token não pode ser vazio');
    }
    
    // 2. Chama repository
    final result = await repository.refreshToken(refreshToken);
    
    // 3. Salva novos tokens (lógica de negócio)
    if (result.authToken != null) {
      await storage.saveToken(result.authToken!);
    }
    if (result.refreshAuthToken != null) {
      await storage.saveRefreshToken(result.refreshAuthToken!);
    }
    
    // 4. Retorna resultado
    return result;
  }
}
```

### 4. **Orquestração de Múltiplos Repositories** 🎼

```dart
// ✅ UseCase orquestrando múltiplos repositories
class CompleteProfileUseCase {
  final AuthRepository authRepository;
  final TherapistRepository therapistRepository;
  
  Future<void> call(ProfileData data) async {
    // 1. Valida dados
    _validateData(data);
    
    // 2. Atualiza usuário
    await authRepository.updateUser(data.userData);
    
    // 3. Cria perfil de terapeuta
    await therapistRepository.createTherapist(data.therapistData);
    
    // 4. Envia notificação (se necessário)
    // await notificationService.send(...);
  }
}
```

### 5. **Inversão de Dependência** 🔄

```dart
// ✅ Bloc não conhece detalhes de implementação
class LoginBloc {
  final LoginUseCase loginUseCase; // Só conhece a interface
  
  // Não precisa saber:
  // - Se vem de API REST, GraphQL, ou Firebase
  // - Como os dados são armazenados
  // - Detalhes de autenticação
}
```

## ⚠️ Quando UseCase pode ser dispensável?

### **Casos Simples (Pass-through)**

Se o UseCase apenas repassa a chamada sem lógica adicional:

```dart
// ❓ Talvez desnecessário
class GetCurrentUserUseCase {
  final AuthRepository repository;
  
  Future<AuthResult> call() {
    return repository.getCurrentUser(); // Apenas repassa
  }
}
```

**Alternativa**: Chamar o Repository diretamente no Bloc.

### **Quando usar mesmo assim?**

Mesmo sendo simples, ainda vale usar se:
- ✅ Você quer manter **consistência arquitetural**
- ✅ Facilita **testes** (mock do UseCase é mais simples)
- ✅ Pode **evoluir** no futuro (adicionar validações, cache, etc.)
- ✅ **Documenta** a intenção ("esta é uma ação de negócio")

## 📊 Comparação: Com vs Sem UseCase

### **Sem UseCase** (mais simples, menos flexível)

```dart
// Bloc → Repository → DataSource
class LoginBloc {
  final AuthRepository repository;
  
  Future<void> login() async {
    final result = await repository.login(email, password);
    // Lógica de negócio misturada aqui
  }
}
```

**Prós:**
- ✅ Menos código
- ✅ Mais direto
- ✅ Menos camadas

**Contras:**
- ❌ Difícil testar isoladamente
- ❌ Lógica de negócio acoplada ao Bloc
- ❌ Difícil reutilizar em outros lugares
- ❌ Se precisar mudar lógica, precisa mudar Bloc

### **Com UseCase** (mais estruturado, mais flexível)

```dart
// Bloc → UseCase → Repository → DataSource
class LoginBloc {
  final LoginUseCase loginUseCase;
  
  Future<void> login() async {
    final result = await loginUseCase(email, password);
    // Foca apenas em estado da UI
  }
}

class LoginUseCase {
  final AuthRepository repository;
  
  Future<AuthResult> call(String email, String password) {
    // Lógica de negócio isolada aqui
    return repository.login(email, password);
  }
}
```

**Prós:**
- ✅ Fácil testar isoladamente
- ✅ Lógica de negócio isolada
- ✅ Reutilizável em vários lugares
- ✅ Fácil evoluir sem afetar Bloc
- ✅ Documenta intenção claramente

**Contras:**
- ❌ Mais código
- ❌ Mais camadas
- ❌ Pode parecer "over-engineering" para casos simples

## 🎯 Recomendação para o Projeto

### **Manter UseCase quando:**
- ✅ Ação tem **lógica de negócio** (validações, transformações)
- ✅ Precisa **orquestrar múltiplos repositories**
- ✅ Precisa **cache, logging, ou side effects**
- ✅ Pode ser **reutilizado** em vários lugares
- ✅ Quer manter **consistência arquitetural**

### **Considerar remover quando:**
- ❌ É apenas um **pass-through** simples
- ❌ Nunca será reutilizado
- ❌ Nunca terá lógica adicional
- ❌ O projeto é muito pequeno e simples

## 📝 Exemplo Real do Projeto

### **GetCurrentTherapistUseCase** (com lógica):

```dart
class GetCurrentTherapistUseCase {
  final TherapistRepository repository;
  final SecureStorageService storage;
  
  Future<Therapist?> call() async {
    // 1. Obtém token do storage (lógica de negócio)
    final token = await storage.getToken();
    if (token == null) {
      throw Exception('Token não encontrado');
    }
    
    // 2. Obtém ID do usuário do token (lógica de negócio)
    final userId = _extractUserIdFromToken(token);
    
    // 3. Busca terapeuta
    return await repository.getTherapistByUserId(userId);
  }
}
```

**Este UseCase é valioso** porque:
- Encapsula lógica de obter token e extrair userId
- Pode ser reutilizado em vários lugares
- Fácil de testar isoladamente
- Se mudar como obtemos o userId, só muda aqui

## 🎓 Conclusão

**UseCase não é obrigatório**, mas é uma **boa prática** que:

1. **Separa responsabilidades** claramente
2. **Facilita testes** e manutenção
3. **Permite evolução** sem quebrar código existente
4. **Documenta** as ações de negócio do sistema

**Para projetos pequenos**, pode parecer "over-engineering", mas **para projetos que vão crescer**, vale muito a pena ter essa estrutura desde o início.

---

**No seu projeto atual**, os UseCases estão bem implementados e seguem o padrão Clean Architecture. Mesmo os simples (como `LoginUseCase`) valem a pena manter para:
- Consistência arquitetural
- Facilidade de testes
- Possibilidade de evolução futura


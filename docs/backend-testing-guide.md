# Guia de Testes para Backend Dart/Shelf

Este documento fornece orientações e prompts reutilizáveis para implementar testes abrangentes em features do backend.

## 📋 Estrutura de Testes

Cada feature do backend deve ter os seguintes tipos de testes:

```
server/test/features/<feature_name>/
├── <feature>.controller_test.dart    # Testes unitários do controller
├── <feature>.handler_test.dart       # Testes unitários do handler
├── <feature>.repository_test.dart    # Testes unitários do repository
├── <feature>.integration_test.dart   # Testes de integração end-to-end
└── helpers/
    └── test_<feature>_repository.dart # Helper para testes com banco
```

## 🎯 Tipos de Testes

### 1. **Testes Unitários de Repository**

Testam a camada de acesso a dados com banco de dados real.

**Cobertura:**

- ✅ CRUD completo (Create, Read, Update, Delete)
- ✅ Filtros e queries complexas
- ✅ RLS (Row Level Security) e permissões
- ✅ Validações de dados
- ✅ Tratamento de erros

### 2. **Testes Unitários de Controller**

Testam a lógica de negócio usando mocks do repository.

**Cobertura:**

- ✅ Validações de regras de negócio
- ✅ Transformações de dados
- ✅ Tratamento de exceções
- ✅ Bypass RLS para admin
- ✅ Casos de erro

### 3. **Testes Unitários de Handler**

Testam as rotas HTTP usando mocks do controller.

**Cobertura:**

- ✅ Parsing de request (query params, body, headers)
- ✅ Validação de autenticação/autorização
- ✅ Códigos de status HTTP corretos
- ✅ Formato de resposta JSON
- ✅ Tratamento de erros HTTP

### 4. **Testes de Integração**

Testam o fluxo completo com servidor real e banco de dados.

**Cobertura:**

- ✅ Fluxos end-to-end completos
- ✅ Autenticação e autorização
- ✅ Interação entre múltiplas features
- ✅ Cenários reais de uso

## 🔧 Ferramentas e Padrões

### Bibliotecas

```yaml
dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0 # Para mocks
```

### Padrões de Código

#### Setup de Mocks

```dart
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MyRepository {}

void main() {
  setUpAll(() {
    // Registrar fallback values para objetos complexos
    registerFallbackValue(MyModel(...));
  });

  late _MockRepository repository;
  late MyController controller;

  setUp(() {
    repository = _MockRepository();
    controller = MyController(repository);
  });
}
```

#### Testes com Banco de Dados

```dart
import 'helpers/test_my_repository.dart';

void main() {
  late TestMyRepository repository;

  setUp(() async {
    repository = TestMyRepository();
    await repository.setup();
  });

  tearDown(() async {
    await repository.teardown();
  });

  test('deve criar registro', () async {
    final created = await repository.create(...);
    expect(created.id, isNotNull);
  });
}
```

## 📝 Prompt Orientativo para Implementação de Testes

Use este prompt quando precisar implementar ou revisar testes de uma feature:

---

### **PROMPT: Implementar Testes para Feature Backend**

```
Preciso implementar testes abrangentes para a feature @[server/lib/features/<FEATURE_NAME>].

**Contexto:**
- Feature: <FEATURE_NAME>
- Componentes: Controller, Handler, Repository
- Modelo principal: <MODEL_NAME>

**Requisitos:**

1. **Analisar Código Existente**
   - Revisar controller, handler e repository
   - Identificar todas as operações CRUD
   - Listar regras de negócio e validações
   - Verificar filtros e queries especiais

2. **Implementar Testes de Repository**
   - Criar `test/features/<feature>/<feature>.repository_test.dart`
   - Testar CRUD completo com banco real
   - Testar todos os filtros e queries
   - Testar RLS (bypassRLS true/false)
   - Testar casos de erro (registro não encontrado, etc)

3. **Implementar Testes de Controller**
   - Criar `test/features/<feature>/<feature>.controller_test.dart`
   - Usar mocks do repository
   - Testar todas as validações de negócio
   - Testar transformações de dados
   - Testar bypass RLS para admin
   - Testar tratamento de exceções

4. **Implementar Testes de Handler**
   - Criar `test/features/<feature>/<feature>.handler_test.dart`
   - Usar mocks do controller
   - Testar parsing de requests
   - Testar autenticação/autorização
   - Testar códigos HTTP corretos
   - Testar formato de resposta JSON

5. **Implementar Testes de Integração**
   - Criar `test/features/<feature>/<feature>.integration_test.dart`
   - Testar fluxos end-to-end completos
   - Usar servidor real e banco de dados
   - Testar autenticação real

6. **Criar Helper de Teste** (se necessário)
   - Criar `test/features/<feature>/helpers/test_<feature>_repository.dart`
   - Implementar setup/teardown de banco
   - Adicionar métodos auxiliares para criar dados de teste

**Padrões a Seguir:**
- Usar `mocktail` para mocks
- Nomear testes descritivamente em português
- Agrupar testes relacionados com `group()`
- Usar `setUp()` e `tearDown()` apropriadamente
- Testar casos de sucesso E casos de erro
- Verificar códigos de status HTTP corretos
- Validar formato de JSON nas respostas

**Resultado Esperado:**
- Cobertura de testes > 80%
- Todos os testes passando
- Documentação clara dos casos testados
```

---

## 📊 Exemplo Completo: Feature Financial

A feature `financial` serve como referência de implementação completa:

### Arquivos de Teste

1. **`financial.controller_test.dart`** (1293 linhas)

   - 60+ testes unitários
   - Cobertura completa de validações
   - Testes de bypass RLS

2. **`financial.handler_test.dart`** (1200 linhas)

   - Testes de todas as rotas HTTP
   - Validação de autenticação
   - Parsing de query parameters

3. **`financial.repository_test.dart`** (713 linhas)

   - CRUD completo
   - Filtros complexos
   - Testes de RLS

4. **`financial.integration_test.dart`**

   - Fluxos end-to-end
   - Autenticação real

5. **`financial_dashboard_test.dart`**

   - Testes de métricas e agregações

6. **`financial_trigger_test.dart`**
   - Testes de triggers SQL

### Estrutura de um Teste de Controller

```dart
group('FinancialController - createTransaction', () {
  test('deve criar transação com dados válidos', () async {
    // Arrange
    when(() => repository.createTransaction(...))
      .thenAnswer((_) async => sampleTransaction);

    // Act
    final result = await controller.createTransaction(...);

    // Assert
    expect(result.id, equals(1));
    expect(result.amount, 100.0);
  });

  test('deve validar valor maior que zero', () async {
    // Arrange
    final invalidTransaction = sampleTransaction.copyWith(amount: 0.0);

    // Act & Assert
    expect(
      () => controller.createTransaction(transaction: invalidTransaction, ...),
      throwsA(isA<FinancialException>()
        .having((e) => e.statusCode, 'statusCode', 400)),
    );
  });
});
```

### Estrutura de um Teste de Handler

```dart
test('POST /financial deve criar transação', () async {
  // Arrange
  when(() => controller.createTransaction(...))
    .thenAnswer((_) async => sampleTransaction);

  final request = createAuthenticatedRequest(
    method: 'POST',
    path: '/financial',
    body: {...},
    userId: 1,
    userRole: 'therapist',
  );

  // Act
  final response = await handler.router.call(request);

  // Assert
  expect(response.statusCode, equals(201));
  final json = jsonDecode(await response.readAsString());
  expect(json['id'], equals(1));
});
```

## ✅ Checklist de Revisão de Testes

Antes de considerar os testes completos, verifique:

- [ ] Todos os métodos públicos estão testados
- [ ] Casos de sucesso E casos de erro estão cobertos
- [ ] Validações de negócio estão testadas
- [ ] RLS está testado (bypassRLS true/false)
- [ ] Códigos HTTP estão corretos (200, 201, 400, 404, 500)
- [ ] Formato JSON das respostas está validado
- [ ] Autenticação/autorização está testada
- [ ] Testes de integração cobrem fluxos principais
- [ ] Todos os testes passam
- [ ] Não há warnings ou erros de lint

## 🚀 Comandos de Execução

```bash
# Executar todos os testes de uma feature
cd server
dart test test/features/<feature>/

# Executar arquivo específico
dart test test/features/<feature>/<feature>.controller_test.dart

# Executar com cobertura
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Executar apenas testes que correspondem a um padrão
dart test --name="deve criar"
```

## 📚 Recursos Adicionais

- [Documentação oficial do package:test](https://pub.dev/packages/test)
- [Documentação do mocktail](https://pub.dev/packages/mocktail)
- [Guia de testes do Dart](https://dart.dev/guides/testing)

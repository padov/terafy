# Testes Automatizados - Terafy Backend

Este documento descreve como executar os testes automatizados do backend.

## Estrutura de Testes

**Padrão oficial do Flutter/Dart**: Os testes estão organizados na pasta `test/` separada de `lib/`:

```
server/
├── lib/
│   └── features/
│       └── therapist/
│           ├── therapist.handler.dart
│           └── therapist.repository.dart
└── test/
    └── features/
        └── therapist/
            ├── therapist.handler_test.dart
            ├── therapist.repository_test.dart
            └── helpers/
                └── test_therapist_repository.dart
```

## Por que separar em `test/`?

✅ **Padrão oficial**: Convenção estabelecida pela comunidade Flutter/Dart  
✅ **Organização**: Separação clara entre código de produção e testes  
✅ **Build**: Testes não são incluídos no build de produção  
✅ **Ferramentas**: IDEs e ferramentas esperam testes em `test/`  
✅ **CI/CD**: Facilita configuração de pipelines  

## Como Executar os Testes

### Instalar Dependências

```bash
cd server
dart pub get
```

### Executar Todos os Testes

```bash
dart test
```

### Executar Testes Específicos

```bash
# Testes do repository
dart test test/features/therapist/therapist.repository_test.dart

# Testes do handler
dart test test/features/therapist/therapist.handler_test.dart

# Todos os testes do therapist
dart test test/features/therapist/
```

### Executar com Cobertura

```bash
dart test --coverage=coverage
```

## Tipos de Testes

### 1. Testes Unitários (Repository)

Testam a lógica do repository isoladamente, usando um mock do banco de dados:

- `getAllTherapists()` - Lista todos os terapeutas
- `getTherapistById()` - Busca por ID
- `createTherapist()` - Cria novo terapeuta
- `updateTherapist()` - Atualiza terapeuta existente
- `deleteTherapist()` - Deleta terapeuta

### 2. Testes de Integração (Handler)

Testam as rotas HTTP e a integração entre handler e repository:

- `GET /therapists` - Lista todos
- `GET /therapists/:id` - Busca por ID
- `POST /therapists` - Cria novo
- `PUT /therapists/:id` - Atualiza existente
- `DELETE /therapists/:id` - Deleta

Cada rota testa:
- Casos de sucesso (200, 201)
- Casos de erro (400, 404, 500)
- Validação de dados
- Respostas JSON corretas

## TestTherapistRepository

A classe `TestTherapistRepository` é um mock do repository que simula o comportamento do banco de dados em memória. Isso permite que os testes sejam:

- **Rápidos** - Não precisam de banco de dados real
- **Isolados** - Cada teste começa com estado limpo
- **Confiáveis** - Não dependem de dados externos

## Exemplo de Teste

```dart
test('deve criar terapeuta com dados válidos', () async {
  final therapist = Therapist(
    name: 'Dr. João Silva',
    email: 'joao@test.com',
  );

  final created = await repository.createTherapist(therapist);

  expect(created.id, isNotNull);
  expect(created.name, 'Dr. João Silva');
  expect(created.email, 'joao@test.com');
});
```

## Adicionando Novos Testes

Para adicionar testes para novas features:

1. Crie a estrutura de pastas em `test/` espelhando `lib/`
2. Crie o arquivo de teste: `test/features/[nome]/[nome]_test.dart`
3. Use o padrão `Test[Nome]Repository` para mocks
4. Siga a estrutura de grupos (`group`) e testes (`test`)
5. Execute `dart test` para verificar

## CI/CD

Os testes podem ser executados em pipelines de CI/CD:

```yaml
# Exemplo GitHub Actions
- name: Run tests
  run: |
    cd server
    dart pub get
    dart test
```

## Cobertura de Código

Para verificar a cobertura de testes:

```bash
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

## Próximos Passos

- [ ] Adicionar testes de integração com banco de dados real (opcional)
- [ ] Configurar CI/CD para executar testes automaticamente
- [ ] Adicionar testes de performance
- [ ] Adicionar testes de segurança (validação de entrada)

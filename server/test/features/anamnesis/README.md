# Testes de Anamnese

Testes automatizados para a funcionalidade de anamnese.

## Estrutura

```
test/features/anamnesis/
├── anamnesis.controller_test.dart    # Testes unitários do controller
├── anamnesis.handler_test.dart        # Testes de integração HTTP
└── helpers/
    └── test_anamnesis_repositories.dart  # Mock repository para testes
```

## Executar Testes

### Todos os testes de anamnese:
```bash
cd server
dart test test/features/anamnesis/
```

### Testes específicos:
```bash
# Apenas testes do controller
dart test test/features/anamnesis/anamnesis.controller_test.dart

# Apenas testes do handler
dart test test/features/anamnesis/anamnesis.handler_test.dart
```

### Com cobertura:
```bash
dart test --coverage=coverage test/features/anamnesis/
```

## Tipos de Testes

### 1. Testes Unitários (Controller)
Testam a lógica do controller isoladamente usando mocks do repository:

- `getAnamnesisByPatientId()` - Busca por paciente
- `getAnamnesisById()` - Busca por ID
- `createAnamnesis()` - Criação (com validação de duplicata)
- `updateAnamnesis()` - Atualização
- `deleteAnamnesis()` - Deleção
- `listTemplates()` - Listagem de templates
- `getTemplateById()` - Busca template
- `createTemplate()` - Criação de template
- `updateTemplate()` - Atualização de template
- `deleteTemplate()` - Deleção de template

### 2. Testes de Integração (Handler)
Testam as rotas HTTP e a integração entre handler e controller:

**Anamnese:**
- `GET /anamnesis/patient/:patientId` - Buscar por paciente
- `GET /anamnesis/:id` - Buscar por ID
- `POST /anamnesis` - Criar
- `PUT /anamnesis/:id` - Atualizar
- `DELETE /anamnesis/:id` - Deletar

**Templates:**
- `GET /anamnesis/templates` - Listar
- `GET /anamnesis/templates/:id` - Buscar por ID
- `POST /anamnesis/templates` - Criar
- `PUT /anamnesis/templates/:id` - Atualizar
- `DELETE /anamnesis/templates/:id` - Deletar

Cada rota testa:
- ✅ Casos de sucesso (200, 201)
- ❌ Casos de erro (400, 404, 500)
- ✅ Validação de dados
- ✅ Respostas JSON corretas

## TestAnamnesisRepository

A classe `TestAnamnesisRepository` é um mock do repository que simula o comportamento do banco de dados em memória. Isso permite que os testes sejam:

- **Rápidos** - Não precisam de banco de dados real
- **Isolados** - Cada teste começa com estado limpo
- **Confiáveis** - Não dependem de dados externos

## Exemplo de Teste

```dart
test('deve criar anamnese com dados válidos', () async {
  final anamnesis = Anamnesis(
    patientId: 1,
    therapistId: 1,
    data: {'test': 'value'},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final created = await repository.createAnamnesis(
    anamnesis,
    userId: 1,
    userRole: 'therapist',
    accountId: 1,
  );

  expect(created.id, isNotNull);
  expect(created.patientId, equals(1));
});
```

## Cobertura Esperada

Os testes cobrem:
- ✅ Todos os métodos do controller
- ✅ Todos os endpoints HTTP
- ✅ Casos de sucesso
- ✅ Casos de erro (404, 400, 409)
- ✅ Validações de negócio
- ✅ Proteção contra templates do sistema

## Próximos Passos

- [ ] Adicionar testes de integração com banco de dados real (opcional)
- [ ] Adicionar testes de performance
- [ ] Adicionar testes de segurança (validação de entrada)
- [ ] Adicionar testes de campos condicionais


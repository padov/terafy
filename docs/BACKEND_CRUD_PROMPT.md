# Prompt Template: Criar Backend CRUD a partir de Migration SQL

Use este prompt quando precisar criar o backend completo (modelo, repository e handler) para uma nova tabela do banco de dados.

## Estrutura do Prompt

```
Vamos criar o backend completo para a tabela [NOME_DA_TABELA] do banco de dados.

O arquivo de migration está em: [CAMINHO_PARA_MIGRATION.sql]

Os modelos devem ser criados em: packages/models/lib/src/
O repository deve ser criado em: server/lib/features/[nome_feature]/
O handler deve ser criado em: server/lib/features/[nome_feature]/

Siga o padrão já estabelecido no projeto:
- Modelo deve ter os métodos fromMap() e toJson()
- Repository deve usar DBConnection e postgres
- Handler deve usar shelf_router com rotas RESTful completas (GET, POST, PUT, DELETE)
- Registrar as rotas no server.dart

Crie:
1. Modelo [NomeModel] no package models
2. Exportar no models.dart
3. Repository [NomeRepository] com métodos CRUD completos
4. Handler [NomeHandler] com rotas RESTful
5. Registrar rotas no server.dart
```

## Exemplo de Uso

```
Vamos criar o backend completo para a tabela appointments do banco de dados.

O arquivo de migration está em: server/db/migrations/20251103000000_create_appointments_table.sql

Os modelos devem ser criados em: packages/models/lib/src/
O repository deve ser criado em: server/lib/features/appointments/
O handler deve ser criado em: server/lib/features/appointments/

Siga o padrão já estabelecido no projeto:
- Modelo deve ter os métodos fromMap() e toJson()
- Repository deve usar DBConnection e postgres
- Handler deve usar shelf_router com rotas RESTful completas (GET, POST, PUT, DELETE)
- Registrar as rotas no server.dart

Crie:
1. Modelo Appointment no package models
2. Exportar no models.dart
3. Repository AppointmentRepository com métodos CRUD completos
4. Handler AppointmentHandler com rotas RESTful
5. Registrar rotas no server.dart
```

## Padrões a Seguir

### 1. Modelo (packages/models/lib/src/[nome]_model.dart)
- Todos os campos da tabela devem ser mapeados
- Campos nullable devem ser opcionais (com `?`)
- Campos JSONB devem ser `Map<String, dynamic>?`
- Campos ARRAY devem ser `List<T>?`
- Campos DATE devem ser `DateTime?`
- Implementar `toJson()` com snake_case para os campos JSON
- Implementar `fromMap()` com conversão adequada de tipos

### 2. Repository (server/lib/features/[nome]/[nome].repository.dart)
- Usar `DBConnection` injetado via construtor
- Métodos: `getAll[Nome]()`, `get[Nome]ById(int id)`, `create[Nome]([Nome] model)`, `update[Nome](int id, [Nome] model)`, `delete[Nome](int id)`
- Para campos JSONB, usar `jsonEncode()` antes de passar para o banco
- Retornar `null` quando não encontrar registro (getById, update)
- Retornar `bool` no delete (true se deletou, false se não encontrou)

### 3. Handler (server/lib/features/[nome]/[nome].handler.dart)
- Usar `shelf_router` com `Router()`
- Rotas:
  - `GET /` - Lista todos
  - `GET /<id>` - Busca por ID
  - `POST /` - Cria novo
  - `PUT /<id>` - Atualiza existente
  - `DELETE /<id>` - Deleta
- Sempre retornar JSON com header `Content-Type: application/json`
- Tratar erros com try-catch
- Validar ID quando necessário
- Retornar 404 quando não encontrar registro
- Retornar 201 para criação
- Retornar 400 para requisições inválidas

### 4. Server (server/bin/server.dart)
- Importar handler e repository
- Criar instância do repository com DBConnection
- Criar instância do handler com repository
- Montar rotas usando `..mount('/[nome-plural]', [nome]Handler.router.call)`

## Checklist

- [ ] Modelo criado com todos os campos
- [ ] Modelo exportado no models.dart
- [ ] Repository criado com todos os métodos CRUD
- [ ] Handler criado com todas as rotas RESTful
- [ ] Rotas registradas no server.dart
- [ ] Sem erros de lint
- [ ] Campos JSONB tratados corretamente (jsonEncode/jsonDecode)
- [ ] Campos DATE tratados corretamente (DateTime.parse)
- [ ] Campos ARRAY tratados corretamente (List.from)


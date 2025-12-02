# Testes de Integração - Terafy Backend

Este documento descreve como executar os testes de integração que testam **endpoints HTTP completos** com o banco de dados real.

## 🎯 O que são Testes de Integração?

Os testes de integração testam a aplicação **end-to-end via HTTP**, validando:

- ✅ **Endpoints HTTP completos** (rotas, middlewares, handlers)
- ✅ **Autenticação e autorização** (JWT, roles, RLS)
- ✅ **Constraints do banco** (UNIQUE, CHECK, FOREIGN KEY) via respostas HTTP
- ✅ **ENUMs** (valores permitidos) via validação de entrada
- ✅ **RLS (Row Level Security)** via tokens diferentes
- ✅ **Fluxos completos** como o cliente usa a API

## 📋 Pré-requisitos

1. **PostgreSQL rodando** (via Docker ou local)
2. **Banco de teste criado**: `terafy_test_db` (criado automaticamente)
3. **Migrations executadas** no banco de teste (executadas automaticamente)

## 🗄️ Banco de Dados de Teste

Os testes usam um banco separado: `terafy_test_db` (não `terafy_db`)

### Configuração

As credenciais padrão são:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `terafy_test_db`
- **User**: `postgres`
- **Password**: `mysecretpassword`

Para alterar, edite `test/helpers/integration_test_db.dart`

## 🚀 Como Executar

### Executar Testes de Integração

```bash
cd server

# Todos os testes de integração
dart test test/features/auth/auth.integration_test.dart
dart test test/features/therapist/therapist.integration_test.dart
dart test test/features/session/session.integration_test.dart
dart test test/features/financial/financial.integration_test.dart
dart test test/features/schedule/schedule.integration_test.dart

# Com output detalhado
dart test test/features/auth/auth.integration_test.dart --reporter expanded
```

## 📁 Estrutura

```
test/
├── helpers/
│   ├── integration_test_db.dart      # Helper para banco de teste
│   ├── test_server_setup.dart       # Setup do servidor HTTP completo
│   └── http_test_helpers.dart       # Helpers para requisições HTTP
└── features/
    └── auth/
        ├── auth.integration_test.dart    # Testes de integração HTTP
        ├── auth.controller_test.dart     # Testes unitários (mocks)
        └── auth.handler_test.dart        # Testes unitários (mocks)
```

## 🔄 Fluxo dos Testes

1. **setUpAll**: Executa uma vez antes de todos os testes
   - Cria banco `terafy_test_db` se não existir
   - **Busca migrations automaticamente** da pasta `db/migrations/`
   - Executa todas as migrations na ordem
   - Limpa dados iniciais

2. **setUp**: Executa antes de cada teste
   - Limpa todas as tabelas
   - Cria Handler HTTP completo (igual ao servidor real)
   - Cria usuários de teste e obtém tokens

3. **Teste**: Executa o teste
   - Faz requisições HTTP reais
   - Valida respostas HTTP (status codes, JSON)
   - Testa middlewares (CORS, auth, logging)
   - Valida constraints/RLS/ENUMs indiretamente via API

4. **tearDown**: Executa após cada teste
   - Limpa todas as tabelas novamente

## ✅ O que é Testado

### Auth (`/auth/*`)
- ✅ `POST /auth/register` - Criação de usuário e tokens
- ✅ `POST /auth/login` - Login e geração de tokens
- ✅ `POST /auth/refresh` - Renovação de access token
- ✅ `GET /auth/me` - Dados do usuário autenticado
- ✅ `POST /auth/logout` - Revogação de tokens
- ✅ Validação de email único (via 409 Conflict)
- ✅ Validação de dados obrigatórios (via 400 Bad Request)

### Therapist (`/therapists/*`)
- ✅ `POST /therapists/me` - Criação de therapist
- ✅ `GET /therapists/me` - Busca therapist do usuário
- ✅ `PUT /therapists/me` - Atualização de therapist
- ✅ `GET /therapists` - Lista todos (admin only)
- ✅ RLS via API (therapist vê apenas seus dados)
- ✅ Validação de email único (via 409 Conflict)

### Session (`/sessions/*`)
- ✅ `POST /sessions` - Criação de sessão
- ✅ `GET /sessions` - Lista sessões
- ✅ `GET /sessions/next-number` - Próximo número de sessão

### Financial (`/financial/*`)
- ✅ `POST /financial` - Criação de transação
- ✅ `GET /financial` - Lista transações
- ✅ `GET /financial/summary` - Resumo financeiro

### Schedule (`/schedule/*`)
- ✅ `GET /schedule/settings` - Configurações de agenda
- ✅ `GET /schedule/appointments` - Lista agendamentos
- ✅ `POST /schedule/appointments` - Cria agendamento

## 🆕 Mudanças da Nova Estrutura

### Antes (Repository/Controller)
- Testava Repository/Controller diretamente
- Não testava rotas, middlewares, validação HTTP
- Código duplicado em helpers

### Agora (HTTP Endpoints)
- ✅ Testa endpoints HTTP completos
- ✅ Testa middlewares (CORS, auth, logging)
- ✅ Testa rotas e validação de entrada
- ✅ Helpers centralizados em `test/helpers/`
- ✅ Migrations descobertas automaticamente
- ✅ Mais realista (como o cliente usa)

## ⚠️ Importante

1. **Banco Separado**: Os testes usam `terafy_test_db`, não `terafy_db`
2. **Dados Limpos**: Cada teste começa com banco limpo
3. **Migrations Automáticas**: São descobertas e executadas automaticamente
4. **RLS**: Testes validam políticas de Row Level Security via tokens diferentes
5. **Constraints**: Validadas indiretamente via respostas HTTP (400/409)

## 🔧 Troubleshooting

### Erro: "database does not exist"
O helper cria automaticamente, mas você pode criar manualmente:
```bash
psql -U postgres -c "CREATE DATABASE terafy_test_db;"
```

### Erro: "relation does not exist"
As migrations são executadas automaticamente. Se falhar:
```bash
cd server
# Verifica se migrations existem
ls db/migrations/
```

### Erro de conexão
- Verifique se PostgreSQL está rodando
- Verifique credenciais em `test/helpers/integration_test_db.dart`
- Verifique se porta 5432 está acessível

## 📊 Comparação: Unitários vs Integração

| Aspecto | Testes Unitários | Testes de Integração |
|---------|------------------|----------------------|
| **Banco** | ❌ Mocks em memória | ✅ PostgreSQL real |
| **HTTP** | ❌ Não testa | ✅ Testa endpoints completos |
| **Middlewares** | ❌ Não testa | ✅ Testa CORS, auth, logging |
| **Rotas** | ❌ Não testa | ✅ Testa rotas e parâmetros |
| **Velocidade** | ⚡ Muito rápidos | 🐢 Mais lentos |
| **Constraints** | ❌ Não testa | ✅ Testa via HTTP |
| **RLS** | ❌ Não testa | ✅ Testa via tokens |
| **ENUMs** | ❌ Não testa | ✅ Testa via validação |
| **Isolamento** | ✅ Total | ⚠️ Depende do banco |

## 💡 Recomendação

- **Desenvolvimento**: Use testes unitários (rápidos)
- **CI/CD**: Execute ambos (unitários + integração)
- **Validação**: Use integração para validar API completa

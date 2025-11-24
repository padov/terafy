# Testes de Integração - Terafy Backend

Este documento descreve como executar os testes de integração que usam o banco de dados real.

## 🎯 O que são Testes de Integração?

Os testes de integração testam a aplicação **com o banco de dados real**, validando:

- ✅ **Constraints do banco** (UNIQUE, CHECK, FOREIGN KEY)
- ✅ **ENUMs** (valores permitidos)
- ✅ **RLS (Row Level Security)** - políticas de segurança
- ✅ **Triggers** (se houver)
- ✅ **Integridade referencial**
- ✅ **Comportamento real** da aplicação + banco

## 📋 Pré-requisitos

1. **PostgreSQL rodando** (via Docker ou local)
2. **Banco de teste criado**: `terafy_test_db`
3. **Migrations executadas** no banco de teste

## 🗄️ Banco de Dados de Teste

Os testes usam um banco separado: `terafy_test_db` (não `terafy_db`)

### Configuração

As credenciais padrão são:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `terafy_test_db`
- **User**: `postgres`
- **Password**: `mysecretpassword`

Para alterar, edite `test/features/auth/helpers/integration_test_db.dart`

## 🚀 Como Executar

### 1. Criar o Banco de Teste

O helper cria automaticamente, mas você pode criar manualmente:

```bash
psql -U postgres -c "CREATE DATABASE terafy_test_db;"
```

### 2. Executar Migrations

O helper executa automaticamente, mas você pode executar manualmente:

```bash
# Via dbmate (se configurado)
dbmate --env-file server/.env --migrations-dir server/db/migrations --database-url "postgres://postgres:mysecretpassword@localhost:5432/terafy_test_db?sslmode=disable" up

# Ou manualmente via psql
psql -U postgres -d terafy_test_db -f server/db/migrations/[arquivo].sql
```

### 3. Executar Testes de Integração

```bash
cd server

# Todos os testes de integração
dart test test/features/auth/auth.integration_test.dart

# Com output detalhado
dart test test/features/auth/auth.integration_test.dart --reporter expanded
```

## 📁 Estrutura

```
test/
└── features/
    └── auth/
        ├── auth.integration_test.dart    # Testes de integração
        ├── auth.controller_test.dart     # Testes unitários (mocks)
        ├── auth.handler_test.dart        # Testes unitários (mocks)
        └── helpers/
            ├── integration_test_db.dart  # Helper para banco de teste
            └── test_auth_repositories.dart # Mocks para testes unitários
```

## 🔄 Fluxo dos Testes

1. **setUpAll**: Executa uma vez antes de todos os testes
   - Cria banco `terafy_test_db` se não existir
   - Executa todas as migrations
   - Limpa dados iniciais

2. **setUp**: Executa antes de cada teste
   - Limpa todas as tabelas
   - Cria novas conexões e repositories

3. **Teste**: Executa o teste
   - Usa banco real
   - Valida constraints, ENUMs, RLS, etc.

4. **tearDown**: Executa após cada teste
   - Limpa todas as tabelas novamente

## ✅ O que é Testado

### Login
- ✅ Criação de tokens no banco
- ✅ Atualização de `lastLoginAt`
- ✅ Constraints de email único
- ✅ Constraints de `account_type` e `account_id`

### Registro
- ✅ Criação de usuário no banco
- ✅ Criação de refresh token no banco
- ✅ Validação de ENUMs (`user_role`, `account_status`)

### Refresh Token
- ✅ Renovação usando token do banco
- ✅ Validação de token revogado
- ✅ Atualização de `last_used_at`

### Logout
- ✅ Revogação de refresh token no banco
- ✅ Adição de access token à blacklist

### Validações do Banco
- ✅ ENUM `user_role` (therapist, patient, admin)
- ✅ ENUM `account_status` (active, suspended, canceled)
- ✅ Constraint de email único
- ✅ Constraint de `account_type` e `account_id`

## ⚠️ Importante

1. **Banco Separado**: Os testes usam `terafy_test_db`, não `terafy_db`
2. **Dados Limpos**: Cada teste começa com banco limpo
3. **Migrations**: São executadas automaticamente no `setUpAll`
4. **RLS**: Testes validam políticas de Row Level Security

## 🔧 Troubleshooting

### Erro: "database does not exist"
```bash
# Cria o banco manualmente
psql -U postgres -c "CREATE DATABASE terafy_test_db;"
```

### Erro: "relation does not exist"
```bash
# Executa migrations manualmente
cd server
dart run test/features/auth/helpers/integration_test_db.dart
```

### Erro de conexão
- Verifique se PostgreSQL está rodando
- Verifique credenciais em `integration_test_db.dart`
- Verifique se porta 5432 está acessível

## 📊 Comparação: Unitários vs Integração

| Aspecto | Testes Unitários | Testes de Integração |
|---------|------------------|----------------------|
| **Banco** | ❌ Mocks em memória | ✅ PostgreSQL real |
| **Velocidade** | ⚡ Muito rápidos | 🐢 Mais lentos |
| **Constraints** | ❌ Não testa | ✅ Testa |
| **RLS** | ❌ Não testa | ✅ Testa |
| **ENUMs** | ❌ Não testa | ✅ Testa |
| **Isolamento** | ✅ Total | ⚠️ Depende do banco |

## 💡 Recomendação

- **Desenvolvimento**: Use testes unitários (rápidos)
- **CI/CD**: Execute ambos (unitários + integração)
- **Validação**: Use integração para validar regras do banco


# Como Criar Usuário de Teste

## Método 1: Via Script Dart (Mais Fácil - Recomendado) ⭐

Execute o script Dart que cria o usuário automaticamente:

```bash
cd server
dart run bin/create_test_user.dart
```

Este script:

- Verifica se o usuário já existe
- Cria o hash da senha automaticamente
- Cria o usuário no banco de dados
- Mostra as credenciais criadas

**Credenciais de teste:**

- Email: `teste@terafy.app.br`
- Senha: `senha123`

## Método 2: Via SQL

Execute o script SQL diretamente:

```bash
gcloud compute ssh terafy-freetier-vm

# Via psql
psql -h localhost -U postgres -d terafy_db -f server/db/scripts/create_test_user.sql

# Ou via docker
docker exec -i terafy_postgres psql -U postgres -d terafy_db < server/db/scripts/create_test_user.sql
```

## Método 3: Via API /auth/register

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@terafy.app.br",
    "password": "senha123"
  }'
```

Este método cria apenas o usuário na tabela `users`. Você precisará:

1. Criar o therapist via `/therapists`
2. Vincular o `user_id` ao therapist

## Verificar se o usuário foi criado

```bash
# Via SQL
psql -h localhost -U postgres -d terafy_db -c "SELECT id, email, role, status FROM users WHERE email = 'teste@terafy.app.br';"

# Via API (precisa estar logado)
curl -X GET http://localhost:8080/auth/me \
  -H "Authorization: Bearer <token_do_login>"
```

## Testar Login

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@terafy.app.br",
    "password": "senha123"
  }'
```

Você deve receber uma resposta com `auth_token`, `refresh_token` e `user`.

### Exemplo de resposta:

```json
{
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "teste@terafy.app.br",
    "role": "therapist",
    "account_type": "therapist",
    "account_id": null,
    "status": "active",
    "email_verified": true
  }
}
```

## Inserir Template Padrão de Anamnese

### Método 1: Via Script Dart (Recomendado) ⭐

```bash
make seed-anamnesis-template
# ou
cd server && dart run bin/seed_default_anamnesis_template.dart
```

### Método 2: Via SQL

```bash
# Via psql
psql -h localhost -U postgres -d terafy_db -f server/db/scripts/seed_default_anamnesis_template.sql

# Ou via docker
docker exec -i postgres_db psql -U postgres -d terafy_db < server/db/scripts/seed_default_anamnesis_template.sql
```

### Verificar Template Criado

```sql
SELECT id, name, category, is_system, is_default, created_at
FROM anamnesis_templates
WHERE is_system = TRUE;
```

## Próximos Passos

1. Teste o login no app Flutter com essas credenciais
2. Após login bem-sucedido, você pode criar o therapist completo
3. Vincule o `user_id` ao therapist criado
4. Insira o template padrão de anamnese para começar a usar

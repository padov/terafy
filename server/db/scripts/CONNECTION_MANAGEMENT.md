# Gerenciamento de Conexões do Banco de Dados

## Visão Geral

Este documento descreve as melhorias implementadas para o gerenciamento de conexões do PostgreSQL, incluindo:
- Usuário específico da aplicação
- Timeout de conexões idle
- Pool de conexões melhorado

## 1. Usuário da Aplicação

### Por que usar um usuário específico?

- **Segurança**: O usuário `postgres` é superuser e tem permissões totais. Usar um usuário específico limita os privilégios apenas ao necessário.
- **Auditoria**: Facilita identificar conexões da aplicação vs. conexões administrativas.
- **Controle**: Permite configurar timeouts específicos por usuário.

### Migration

A migration `20251124000000_create_app_user.sql` cria o usuário `terafy_app` com:
- Permissões apenas no schema `public`
- Timeout de 5 minutos para conexões idle em transação
- Sem privilégios de superuser

### Configuração

Após executar a migration, atualize o arquivo `.env`:

```bash
DB_USER=terafy_app
DB_PASSWORD=terafy_app_password
```

**Nota**: Para desenvolvimento inicial, você pode continuar usando `postgres` até executar a migration.

## 2. Timeout de Conexões Idle

### Configurações do PostgreSQL

O `docker-compose.yml` agora inclui:

```yaml
command: >
  postgres
  -c max_connections=200
  -c shared_buffers=256MB
  -c idle_in_transaction_session_timeout=300000  # 5 minutos
  -c statement_timeout=30000                     # 30 segundos
```

### Timeout por Usuário

O usuário `terafy_app` tem timeout específico configurado na migration:
- `idle_in_transaction_session_timeout = 5min`: Encerra conexões idle em transação após 5 minutos
- Isso previne conexões "presas" em transações abertas

## 3. Pool de Conexões Melhorado

### Funcionalidades

1. **Rastreamento de Uso**: Cada conexão tem timestamp da última utilização
2. **Limpeza Automática**: Remove conexões idle há mais de 4 minutos (menor que o timeout do PostgreSQL)
3. **Limpeza Periódica**: Executa a cada 30 segundos
4. **Limite Inteligente**: Mantém mínimo de 2 conexões, máximo de 10

### Como Funciona

```dart
// Ao obter uma conexão
final conn = await pool.getConnection();
// Timestamp é atualizado automaticamente

// Ao devolver uma conexão
pool.releaseConnection(conn);
// Timestamp é atualizado

// Limpeza automática (a cada 30s)
// Remove conexões idle há mais de 4 minutos
```

## 4. Monitoramento

### Verificar Conexões Ativas

```sql
-- Ver todas as conexões
SELECT 
  pid,
  usename,
  datname,
  state,
  state_change,
  now() - state_change as idle_duration,
  query
FROM pg_stat_activity
WHERE datname = 'terafy_db'
ORDER BY state_change;

-- Ver apenas conexões do usuário da aplicação
SELECT 
  pid,
  usename,
  state,
  now() - state_change as idle_duration
FROM pg_stat_activity
WHERE datname = 'terafy_db'
  AND usename = 'terafy_app'
ORDER BY state_change;

-- Contar conexões por usuário
SELECT usename, count(*) as connections
FROM pg_stat_activity
WHERE datname = 'terafy_db'
GROUP BY usename;
```

### Matar Conexões Idle

```sql
-- Matar conexões idle há mais de 5 minutos
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'terafy_db'
  AND state = 'idle'
  AND state_change < now() - interval '5 minutes'
  AND pid <> pg_backend_pid();
```

## 5. Migração

### Passo a Passo

1. **Execute a migration**:
   ```bash
   # A migration será executada automaticamente no próximo restart do servidor
   # Ou execute manualmente:
   docker exec -it terafy_postgres psql -U postgres -d terafy_db -f /docker-entrypoint-initdb.d/20251124000000_create_app_user.sql
   ```

2. **Atualize o `.env`**:
   ```bash
   DB_USER=terafy_app
   DB_PASSWORD=terafy_app_password
   ```

3. **Reinicie os serviços**:
   ```bash
   docker compose restart server
   ```

4. **Verifique as conexões**:
   ```sql
   SELECT usename, count(*) FROM pg_stat_activity WHERE datname = 'terafy_db' GROUP BY usename;
   ```

## 6. Troubleshooting

### Erro: "password authentication failed"

- Verifique se a migration foi executada
- Confirme que `DB_USER` e `DB_PASSWORD` estão corretos no `.env`

### Muitas conexões ainda abertas

- Verifique se todos os repositories estão usando `withConnection()`
- Execute a query de monitoramento para identificar conexões idle
- Considere reduzir `_maxPoolSize` se necessário

### Conexões sendo encerradas muito rápido

- Aumente `idle_in_transaction_session_timeout` no PostgreSQL
- Aumente `_idleTimeout` no pool (atualmente 4 minutos)

## 7. Configurações Recomendadas

### Desenvolvimento
- `max_connections`: 200
- `idle_in_transaction_session_timeout`: 5 minutos
- Pool: 2-10 conexões

### Produção
- `max_connections`: 100-200 (depende do servidor)
- `idle_in_transaction_session_timeout`: 5 minutos
- Pool: 5-15 conexões (ajuste conforme carga)
- Use SSL (`DB_SSL_MODE=require`)


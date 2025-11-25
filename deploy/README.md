# 🐳 Docker Setup - Terafy Server

Configuração Docker completa para rodar o servidor Terafy localmente e preparar para deploy na Google Cloud.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Portas 5432, 8080 (e opcionalmente 80, 443) disponíveis

## 🚀 Início Rápido

### 1. Configurar variáveis de ambiente

```bash
cd docker
cp .env.example .env
```

Edite o arquivo `.env` e configure:
- `DB_PASSWORD`: Senha do PostgreSQL
- `JWT_SECRET_KEY`: Chave secreta para JWT (gere uma chave segura)

**Gerar JWT_SECRET_KEY:**
```bash
# Linux/Mac
openssl rand -base64 64

# Ou usando Python
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

### 2. Iniciar os serviços

```bash
# Apenas banco e servidor
docker-compose up -d

# Com Nginx (reverse proxy)
docker-compose --profile with-nginx up -d
```

### 3. Executar migrations

As migrations são executadas automaticamente na primeira inicialização do PostgreSQL. Se precisar executar manualmente:

```bash
# Opção 1: Via script
chmod +x run-migrations.sh
./run-migrations.sh

# Opção 2: Via container
docker-compose exec server dart run bin/reset_database.dart
```

### 4. Verificar se está funcionando

```bash
# Testar servidor
curl http://localhost:8080/ping
# Deve retornar: pong

# Se estiver usando Nginx
curl http://localhost/ping
```

## 📁 Estrutura de Arquivos

```
docker/
├── docker-compose.yml    # Orquestração dos serviços
├── Dockerfile            # Build da imagem do servidor
├── .env.example          # Template de variáveis de ambiente
├── .env                  # Suas variáveis (não commitado)
├── nginx.conf            # Configuração do Nginx (opcional)
├── run-migrations.sh     # Script para executar migrations
└── README.md             # Este arquivo
```

## 🔧 Comandos Úteis

### Gerenciar containers

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose stop

# Parar e remover containers
docker-compose down

# Ver logs
docker-compose logs -f

# Ver logs apenas do servidor
docker-compose logs -f server

# Rebuild após mudanças no código
docker-compose build server
docker-compose up -d server
```

### Banco de dados

```bash
# Conectar ao PostgreSQL
docker-compose exec postgres_db psql -U postgres -d terafy_db

# Backup do banco
docker-compose exec postgres_db pg_dump -U postgres terafy_db > backup.sql

# Restaurar backup
docker-compose exec -T postgres_db psql -U postgres terafy_db < backup.sql
```

### Desenvolvimento

```bash
# Rebuild completo
docker-compose build --no-cache

# Limpar volumes (apaga dados do banco!)
docker-compose down -v

# Executar comandos no container do servidor
docker-compose exec server bash
```

## 🌐 Configuração do Nginx

O Nginx é opcional e só inicia com o profile `with-nginx`:

```bash
docker-compose --profile with-nginx up -d
```

### Configurar HTTPS

1. Coloque seus certificados SSL em `docker/ssl/`:
   - `cert.pem`
   - `key.pem`

2. Descomente a seção HTTPS no `nginx.conf`

3. Reinicie o Nginx:
```bash
docker-compose restart nginx
```

## 🔒 Segurança

### Para desenvolvimento local:
- ✅ SSL desabilitado no banco (`DB_SSL_MODE=disable`)
- ✅ Portas expostas localmente

### Para produção:
- ⚠️ **MUDE** `DB_SSL_MODE=require`
- ⚠️ **USE** Secret Manager para senhas
- ⚠️ **CONFIGURE** firewall adequadamente
- ⚠️ **USE** HTTPS com certificados válidos

## 🚀 Deploy na Google Cloud

### Opção 1: VM única (Free Tier)

1. Criar VM e2-micro na região gratuita
2. Instalar Docker e Docker Compose na VM
3. Copiar esta pasta `docker/` para a VM
4. Configurar `.env` com valores de produção
5. Executar `docker-compose up -d`

### Opção 2: Cloud Run + Cloud SQL

1. Build da imagem:
```bash
docker build -f docker/Dockerfile -t gcr.io/SEU_PROJECT/terafy-server ..
```

2. Push para Google Container Registry:
```bash
docker push gcr.io/SEU_PROJECT/terafy-server
```

3. Deploy no Cloud Run (veja documentação do Google Cloud)

## 🐛 Troubleshooting

### Servidor não inicia

```bash
# Ver logs
docker-compose logs server

# Verificar se o banco está saudável
docker-compose ps
```

### Erro de conexão com banco

- Verifique se `DB_HOST=postgres_db` no `.env`
- Verifique se o PostgreSQL está rodando: `docker-compose ps postgres_db`
- Teste conexão: `docker-compose exec postgres_db psql -U postgres`

### Porta já em uso

Altere as portas no `.env`:
```env
DB_PORT=5433
SERVER_PORT=8081
```

### Migrations não executam

Execute manualmente:
```bash
./run-migrations.sh
```

## 📝 Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DB_HOST` | Host do PostgreSQL | `postgres_db` |
| `DB_PORT` | Porta do PostgreSQL | `5432` |
| `DB_NAME` | Nome do banco | `terafy_db` |
| `DB_USER` | Usuário do banco | `postgres` |
| `DB_PASSWORD` | Senha do banco | `mysecretpassword` |
| `DB_SSL_MODE` | Modo SSL (`disable` ou `require`) | `disable` |
| `SERVER_PORT` | Porta do servidor | `8080` |
| `JWT_SECRET_KEY` | Chave secreta JWT | **obrigatório** |
| `JWT_EXPIRATION_DAYS` | Dias até expiração do token | `7` |

## 📚 Recursos

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Google Cloud Run](https://cloud.google.com/run)
- [Cloud SQL](https://cloud.google.com/sql)


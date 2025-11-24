# 🚀 Deploy no Google Cloud - Guia Completo

Este guia explica como fazer o deploy do Terafy no Google Cloud usando Docker.

## 📋 Pré-requisitos

- Conta no Google Cloud Platform
- `gcloud` CLI instalado e configurado
- Docker instalado localmente (para testar antes)

## 🎯 Opções de Deploy

### Opção 1: VM única (Free Tier) - RECOMENDADO PARA COMEÇAR

Usa uma VM e2-micro gratuita com tudo rodando em Docker Compose.

#### Passo 1: Criar a VM

```bash
# Criar VM e2-micro na região gratuita
gcloud compute instances create terafy-freetier-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --boot-disk-type=pd-standard \
  --tags=http-server,https-server
```

#### Passo 2: Configurar Firewall

```bash
# Permitir HTTP e HTTPS
gcloud compute firewall-rules create allow-http-https \
  --allow tcp:80,tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow HTTP and HTTPS"
```

#### Passo 3: Conectar na VM e Instalar Docker

```bash
# Conectar via SSH
gcloud compute ssh terafy-freetier-vm

# Na VM, instalar Docker (método recomendado)
# Opção 1: Usar o script de instalação (mais fácil)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# IMPORTANTE: Fazer logout e login novamente OU executar:
newgrp docker

# Verificar instalação
docker --version
docker compose version
```

#### Passo 4: Upload do Código para a VM

```bash
# Na sua máquina local, comprimir o projeto (excluindo app, build e .git)
cd /Users/marcio.padovani/Projetos/ScoreGame
tar --exclude='app' --exclude='docs' --exclude='.vscode' --exclude='build' --exclude='.git' --exclude='*.md' -czf terafy.tar.gz terafy/

# Copiar para a VM
gcloud compute scp terafy.tar.gz terafy-freetier-vm:~/ 

# Na VM, extrair (removendo pasta antiga se existir)
gcloud compute ssh terafy-freetier-vm
cd ~
# Remover código antigo se existir (garante limpeza - IMPORTANTE!)
rm -rf terafy
# Extrair novo código
tar -xzf terafy.tar.gz
cd terafy/docker
```

#### Passo 5: Configurar Variáveis de Ambiente

```bash
# Na VM
cd ~/terafy/docker
cp env.example .env
nano .env  # Editar com os valores
```

**Configuração do .env:**
```env
# Banco de dados (rodando no Docker na mesma VM)
DB_HOST=postgres_db
DB_PORT=5432
DB_NAME=terafy_db
DB_USER=postgres
DB_PASSWORD=sua-senha-super-segura-aqui
DB_SSL_MODE=disable  # Local na mesma VM, SSL não necessário

# Servidor
SERVER_PORT=8080

# JWT - Gere uma chave segura
JWT_SECRET_KEY=$(openssl rand -base64 64)
JWT_EXPIRATION_DAYS=7

# Nginx (opcional)
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

**Gerar JWT_SECRET_KEY:**
```bash
# Na VM, execute:
openssl rand -base64 64
# Copie o resultado e cole no .env
```

#### Passo 6: Iniciar os Serviços

```bash
# Na VM, dentro de ~/terafy/docker

# IMPORTANTE: Use docker-compose.yml (não .prod.yml)
# O .prod.yml é para Cloud SQL externo, mas você está usando PostgreSQL local

# Build e start (tudo na mesma VM: PostgreSQL, Server e Nginx)
# IMPORTANTE: Use docker-compose.yml (tem PostgreSQL local)
# O docker-compose.prod.yml é para Cloud SQL externo
docker compose build
docker compose up -d

# Ver logs de todos os serviços
docker compose logs -f

# Ver logs apenas do servidor
docker compose logs -f server

# Ver status
docker compose ps
```

**✅ Migrations automáticas:** O servidor executa migrations automaticamente na inicialização! 

- Verifica quais migrations já foram executadas
- Executa apenas as migrations pendentes
- Se houver erro, o servidor não inicia (verifique os logs)

**Verificar se migrations foram executadas:**
```bash
# Ver logs do servidor
docker compose logs server | grep -i migration

# Verificar tabelas no banco
docker compose exec postgres_db psql -U postgres -d terafy_db -c "\dt"
```

#### Passo 7: Verificar se Está Funcionando

```bash
# 1. Verificar se os containers estão rodando
docker compose ps
# Deve mostrar: postgres_db, terafy_server (e opcionalmente terafy_nginx)

# 2. Testar servidor diretamente (porta 8080)
curl http://localhost:8080/ping
# Deve retornar: pong

# 3. Se o Nginx estiver rodando, testar via porta 80
curl http://localhost/ping
# Deve retornar: pong

# 4. Verificar logs se houver problemas
docker compose logs server
docker compose logs postgres_db

# 5. Verificar se o banco está rodando e tem as tabelas
docker compose exec postgres_db psql -U postgres -d terafy_db -c "\dt"
# Deve listar as tabelas criadas pelas migrations

# 6. Verificar logs de migrations (o servidor executa automaticamente)
docker compose logs server | grep -i migration
# Deve mostrar: "✅ Migrations verificadas com sucesso"
```

**Se o servidor não responder na porta 8080:**
```bash
# Verificar logs do servidor
docker compose logs -f server

# Verificar se o container está rodando
docker compose ps server

# Reiniciar o servidor se necessário
docker compose restart server
```

**Se quiser usar Nginx (opcional):**
```bash
# Iniciar com profile do Nginx
docker compose --profile with-nginx up -d

# Verificar se Nginx está rodando
docker compose ps nginx
```

### Opção 2: Com Nginx (Reverse Proxy)

Se quiser usar Nginx como reverse proxy na frente do servidor:

```bash
# Na VM, iniciar com profile do Nginx
cd ~/terafy/docker
docker compose --profile with-nginx up -d

# Verificar
curl http://localhost/ping
```

**Configurar HTTPS (opcional):**
1. Obter certificados SSL (Let's Encrypt)
2. Colocar em `docker/ssl/cert.pem` e `docker/ssl/key.pem`
3. Descomentar seção HTTPS no `nginx.conf`
4. Reiniciar: `docker compose restart nginx`

### Opção 3: Cloud Run + Cloud SQL (Serverless) - NÃO USAR SE TUDO ESTÁ NA VM

Mais moderno, mas requer ajustes no docker-compose.

#### Passo 1: Build e Push da Imagem

```bash
# Configurar projeto
gcloud config set project SEU_PROJECT_ID

# Habilitar APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com

# Build da imagem
cd docker
gcloud builds submit --tag gcr.io/SEU_PROJECT_ID/terafy-freetier-vm:latest

# Ou usar Docker local
docker build -f Dockerfile -t gcr.io/SEU_PROJECT_ID/terafy-freetier-vm:latest ..
docker push gcr.io/SEU_PROJECT_ID/terafy-freetier-vm:latest
```

#### Passo 2: Deploy no Cloud Run

```bash
gcloud run deploy terafy-freetier-vm \
  --image gcr.io/SEU_PROJECT_ID/terafy-freetier-vm:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars "DB_HOST=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME" \
  --set-env-vars "DB_PORT=5432" \
  --set-env-vars "DB_NAME=terafy_db" \
  --set-env-vars "DB_USER=postgres" \
  --set-env-vars "DB_SSL_MODE=require" \
  --add-cloudsql-instances PROJECT_ID:REGION:INSTANCE_NAME \
  --set-secrets "DB_PASSWORD=DB_PASSWORD_SECRET:latest" \
  --set-secrets "JWT_SECRET_KEY=JWT_SECRET_KEY_SECRET:latest"
```

#### Passo 3: Configurar Secret Manager

```bash
# Criar secrets
echo -n "sua-senha-do-db" | gcloud secrets create DB_PASSWORD_SECRET --data-file=-
echo -n "sua-jwt-secret-key" | gcloud secrets create JWT_SECRET_KEY_SECRET --data-file=-

# Dar permissão ao Cloud Run
PROJECT_NUMBER=$(gcloud projects describe SEU_PROJECT_ID --format="value(projectNumber)")
gcloud secrets add-iam-policy-binding DB_PASSWORD_SECRET \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## 🔒 Segurança

### Checklist de Segurança

- [ ] ✅ Senha forte do PostgreSQL no `.env`
- [ ] ✅ JWT_SECRET_KEY forte (mínimo 64 caracteres, gerado com `openssl rand -base64 64`)
- [ ] ✅ Firewall configurado (apenas portas 80, 443, 22)
- [ ] ✅ `.env` não commitado no git (já está no .gitignore)
- [ ] ✅ Backups do volume do PostgreSQL (configurar script de backup)
- [ ] ✅ Logs e monitoramento configurados
- [ ] ✅ HTTPS configurado no Nginx (Let's Encrypt recomendado)

## 📊 Monitoramento

### Ver Logs

```bash
# VM
docker compose logs -f server

# Cloud Run
gcloud run services logs read terafy-freetier-vm --region us-central1
```

### Verificar Saúde

```bash
# Testar endpoint
curl http://SEU_IP_OU_DOMINIO/ping
```

## 🔧 Troubleshooting

### Erro de Conexão com Banco

1. Verificar se o PostgreSQL está rodando:
   ```bash
   docker compose ps postgres_db
   ```

2. Verificar logs do PostgreSQL:
   ```bash
   docker compose logs postgres_db
   ```

3. Testar conexão manual:
   ```bash
   docker compose exec postgres_db psql -U postgres -d terafy_db
   ```

4. Verificar se `DB_HOST=postgres_db` no `.env` (nome do serviço no docker-compose)

### Erro de Permissões

```bash
# Na VM, verificar permissões do Docker
sudo usermod -aG docker $USER
newgrp docker
```

### Rebuild após Mudanças

```bash
# Na VM
cd ~/terafy/docker

# Rebuild apenas do servidor
docker compose build server
docker compose up -d server

# Rebuild completo
docker compose build --no-cache
docker compose up -d
```

### Backup do Banco de Dados

```bash
# Na VM, criar backup
docker compose exec postgres_db pg_dump -U postgres terafy_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
docker compose exec -T postgres_db psql -U postgres terafy_db < backup_YYYYMMDD_HHMMSS.sql
```

### Verificar Migrations

O servidor executa migrations automaticamente. Para verificar:

```bash
# Ver logs de migrations
docker compose logs server | grep -i migration

# Verificar tabelas no banco
docker compose exec postgres_db psql -U postgres -d terafy_db -c "\dt"

# Se migrations não executaram, verificar logs de erro
docker compose logs server | tail -50
```

## 💰 Custos Estimados

### VM única com tudo (Free Tier) - SUA CONFIGURAÇÃO
- VM e2-micro: **GRÁTIS** (dentro do free tier)
- PostgreSQL, Nginx e Server rodando na mesma VM
- **Total: GRÁTIS** (dentro do free tier do Google Cloud)

**Limitações do Free Tier:**
- 1 VM e2-micro por mês
- 30 GB de disco SSD
- 1 GB de RAM
- 1 GB de egress (saída) de rede por mês

**Recomendação:** Para produção com mais tráfego, considere upgrade para e2-small ou e2-medium.

## 🔄 Atualizar o Sistema

Para atualizar o código na VM após mudanças, consulte o guia completo:

📖 **[ATUALIZAR_SISTEMA.md](./ATUALIZAR_SISTEMA.md)** - Guia completo de atualização

**Resumo rápido:**
```bash
# 1. Local: Comprimir código
cd /Users/marcio.padovani/Projetos/ScoreGame
tar --exclude='app' --exclude='docs' --exclude='.vscode' --exclude='build' --exclude='.git' --exclude='*.md' -czf terafy.tar.gz terafy/

# 2. Upload para VM
gcloud compute scp terafy.tar.gz terafy-freetier-vm:~/

# 3. Na VM: Atualizar
gcloud compute ssh terafy-freetier-vm
cd ~ && tar -xzf terafy.tar.gz
cd terafy/docker
docker compose build server
docker compose restart server
```

## 📚 Recursos

- [Google Cloud Free Tier](https://cloud.google.com/free)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Compute Engine Documentation](https://cloud.google.com/compute/docs)


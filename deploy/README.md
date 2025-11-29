# 🚀 Sistema de Deploy - Terafy

Sistema completo para compilar o servidor Dart no Mac e gerar um pacote pronto para deploy na VM Linux (Google Cloud).

## 📋 Visão Geral

Este sistema permite:
- ✅ Compilar servidor Dart no **Mac** e gerar binário **Linux**
- ✅ Criar pasta completa com tudo que a VM precisa
- ✅ Gerar pacote tar.gz pronto para upload
- ✅ Enviar automaticamente para a VM (opcional)

## 🏗️ Estrutura de Arquivos

```
new-deploy/
├── Makefile                      # Makefile com comandos facilitados
├── Dockerfile.build              # Dockerfile para compilar Linux no Mac
├── build-linux.sh                # Script para compilar usando Docker
├── prepare-deploy.sh             # Script principal (build + preparar pasta)
├── build-and-deploy.sh           # Wrapper (usa prepare-deploy.sh)
├── docker-compose.runtime.yml    # Docker Compose para VM
├── Dockerfile.runtime            # Dockerfile runtime (só copia binário)
├── env.example                   # Template de variáveis de ambiente
├── nginx.conf                    # Configuração do Nginx
├── update-binario.sh             # Script para atualizar na VM
└── README.md                     # Este arquivo
```

## 🚀 Como Usar

### 🎯 Usando Makefile (Recomendado)

O Makefile facilita o uso dos comandos:

```bash
cd new-deploy

# Ver todos os comandos disponíveis
make help

# Compilar servidor para Linux
make build

# Preparar pacote completo (build + pasta)
make prepare

# Deploy completo para VM
make deploy VM_NAME=terafy-freetier-vm

# Limpar arquivos gerados
make clean

# Ver versão atual
make version

# Ver informações do pacote
make info

# Listar conteúdo da pasta de deploy
make list
```

### 📝 Usando Scripts Diretamente

#### Opção 1: Build + Preparar pasta (sem enviar)

```bash
cd new-deploy
./prepare-deploy.sh
```

Isso irá:
1. Compilar o servidor para Linux (usando Docker se no Mac)
2. Criar pasta `terafy-deploy/` com tudo necessário
3. Criar pacote `terafy-deploy.tar.gz`

**Resultado:**
- Pasta: `new-deploy/terafy-deploy/`
- Pacote: `new-deploy/terafy-deploy-VERSION.tar.gz` (ex: `terafy-deploy-0.2.0.tar.gz`)

> **Nota:** O nome do pacote inclui automaticamente a versão do `server/pubspec.yaml` (semver).

#### Opção 2: Build + Preparar + Enviar para VM

```bash
cd new-deploy
./prepare-deploy.sh terafy-freetier-vm
```

Isso faz tudo da Opção 1 + envia automaticamente para a VM.

#### Opção 3: Apenas build (para testar)

```bash
cd new-deploy
./build-linux.sh
```

Compila apenas o binário em `new-deploy/build/server`.

## 📦 O que é criado na pasta `terafy-deploy/`

Após executar `prepare-deploy.sh`, a pasta `terafy-deploy/` conterá:

```
terafy-deploy/
├── server                  # Binário Linux compilado
├── migrations/             # Todas as migrations SQL
│   ├── 0000000000001_create_migrations_table.sql
│   ├── 20251102000001_create_users_table.sql
│   └── ... (todos os arquivos)
├── docker-compose.yml      # Config para rodar na VM
├── Dockerfile             # Dockerfile runtime
├── env.example            # Template de variáveis
├── nginx.conf             # Config do Nginx
├── update-binario.sh      # Script útil para atualizar
└── README.md              # Instruções para a VM
```

## 🖥️ Na VM (Linux Debian)

### Primeira Instalação

**Opção 1: Usando o script (Recomendado)**

```bash
# O script update-binario.sh já está em ~/ após o deploy
# Ele faz tudo automaticamente:
./update-binario.sh
```

**Opção 2: Manual**

```bash
# 1. Extrair pacote
cd ~
mkdir -p terafy-deploy
cd terafy-deploy
tar -xzf ~/terafy-deploy-*.tar.gz

# 2. Configurar variáveis de ambiente
cp env.example .env
nano .env  # Editar com os valores corretos

# 3. Iniciar serviços
docker compose build server
docker compose up -d

# 4. Verificar
docker compose ps
curl http://localhost:8080/ping
```

### Atualização

O script `update-binario.sh` é enviado automaticamente para a raiz da VM (`~/`) durante o deploy.

```bash
# Conectar na VM
make gcloud

# Dentro da VM, executar (já está em ~/)
./update-binario.sh
```

Ou manualmente:

```bash
cd ~/terafy-deploy
docker compose down
# O script busca automaticamente o arquivo com versão, ou use:
tar -xzf ~/terafy-deploy-*.tar.gz
docker compose build server
docker compose up -d
```

## 📌 Versionamento

O sistema lê automaticamente a versão do arquivo `server/pubspec.yaml` e inclui no nome do pacote:

- **Formato:** `terafy-deploy-VERSION.tar.gz`
- **Exemplo:** `terafy-deploy-0.2.0.tar.gz`

Para ver a versão atual:
```bash
make version
```

## 🔧 Como Funciona

### 1. Compilação Cross-Platform

**No Mac:**
- Usa Docker com imagem `dart:stable` (Linux)
- Compila dentro do container Linux
- Extrai o binário para a máquina local

**No Linux:**
- Compila diretamente com `dart compile exe`

### 2. Preparação da Pasta

O script `prepare-deploy.sh`:
1. Compila o executável Linux
2. Copia binário para `terafy-deploy/server`
3. Copia todas as migrations
4. Copia arquivos de configuração (docker-compose, Dockerfile, etc.)
5. Cria README com instruções
6. Gera pacote tar.gz

### 3. Deploy na VM

O pacote contém tudo necessário:
- Binário já compilado (não precisa Dart SDK na VM)
- Migrations para o banco
- Configurações Docker prontas
- Scripts de atualização

**Nome do arquivo:** O pacote é nomeado com a versão semver (ex: `terafy-deploy-0.2.0.tar.gz`), facilitando o controle de versões e rollbacks.

**Script de atualização:** O `update-binario.sh` é enviado automaticamente para a raiz da VM (`~/`) durante o deploy, facilitando a execução direta após conectar na VM.

## 📝 Variáveis de Ambiente

Edite o `.env` na VM com:

```env
# Banco de dados
DB_HOST=postgres_db
DB_PORT=5432
DB_NAME=terafy_db
DB_USER=terafy_app
DB_PASSWORD=sua-senha-segura

# SSL do Banco
DB_SSL_MODE=disable  # ou 'require' em produção

# Servidor
SERVER_PORT=8080

# JWT
JWT_SECRET_KEY=sua-chave-secreta-super-segura
JWT_EXPIRATION_DAYS=7

# Nginx (opcional)
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
```

## 🐛 Troubleshooting

### Erro ao compilar no Mac

```bash
# Verificar se Docker está rodando
docker ps

# Limpar cache do Docker
docker system prune -f

# Rebuild forçado
docker build --no-cache -f Dockerfile.build --target build -t terafy-build:latest ..
```

### Binário não funciona na VM

```bash
# Verificar arquitetura do binário
file server

# Deve mostrar: ELF 64-bit LSB executable, x86-64
```

### Erro ao extrair binário do container

```bash
# Verificar se o container foi criado
docker ps -a | grep terafy-build

# Ver logs do build
docker build -f Dockerfile.build --target build -t terafy-build:latest ..
```

## 📊 Comparação de Métodos

| Método | Tamanho | Tempo Build | Tempo Upload |
|--------|---------|-------------|--------------|
| **Código fonte** | ~50-200MB | 3-5 min (na VM) | 1-2 min |
| **Binário** | ~10-20MB | 30s (local) | 10-20s |

## ✅ Vantagens

- ✅ **Cross-platform**: Compila Linux no Mac usando Docker
- ✅ **Rápido**: Binário pré-compilado, não precisa compilar na VM
- ✅ **Completo**: Pasta com tudo necessário
- ✅ **Automatizado**: Um comando faz tudo
- ✅ **Organizado**: Estrutura clara e documentada

## 📚 Próximos Passos

1. Execute `./prepare-deploy.sh` para testar localmente
2. Verifique a pasta `terafy-deploy/` criada
3. Envie para a VM: `./prepare-deploy.sh terafy-freetier-vm`
4. Na VM, extraia e configure o `.env`
5. Inicie os serviços com `docker compose up -d`

## 🔗 Links Úteis

- [Documentação Docker](https://docs.docker.com/)
- [Dart Compile](https://dart.dev/tools/dart-compile)
- [Google Cloud Compute](https://cloud.google.com/compute)


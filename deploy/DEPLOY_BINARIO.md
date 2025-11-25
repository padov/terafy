# 🚀 Deploy com Binário Pré-compilado

Este método compila o servidor localmente e envia apenas o binário para a VM, tornando o deploy muito mais rápido.

## 📋 Vantagens

- ✅ **Muito mais rápido** - não precisa compilar na VM
- ✅ **Arquivo menor** - apenas binário + migrations (~10-20MB vs centenas de MB)
- ✅ **Não precisa Dart SDK na VM** - apenas Docker
- ✅ **Build mais confiável** - compila no seu ambiente conhecido

## 🔧 Pré-requisitos

- Dart SDK instalado localmente
- `gcloud` CLI configurado
- Acesso SSH à VM

## 🚀 Processo de Deploy

### Opção 1: Usar o Script Automatizado (Recomendado)

```bash
# Na sua máquina local
cd /Users/marcio.padovani/Projetos/ScoreGame/terafy/docker

# Executar script (compila e envia automaticamente)
./build-and-deploy.sh terafy-freetier-vm

# Ou se a VM tiver outro nome
./build-and-deploy.sh nome-da-sua-vm
```

### Opção 2: Manual (Passo a Passo)

#### Passo 1: Compilar Localmente

```bash
# Na sua máquina local
cd /Users/marcio.padovani/Projetos/ScoreGame/terafy/server

# Compilar o servidor
dart compile exe bin/server.dart -o ../docker/build/server

# Verificar se compilou
ls -lh ../docker/build/server
```

#### Passo 2: Preparar Pacote

```bash
cd /Users/marcio.padovani/Projetos/ScoreGame/terafy/docker

# Criar diretório de build
mkdir -p build/migrations

# Copiar binário
cp build/server build/server  # Já está lá do passo 1

# Copiar migrations
cp -r ../server/db/migrations/* build/migrations/

# Copiar arquivos Docker necessários
cp docker-compose.runtime.yml build/docker-compose.yml
cp Dockerfile.runtime build/Dockerfile
cp env.example build/
cp nginx.conf build/ 2>/dev/null || true

# Criar pacote
cd build
tar -czf ../terafy-deploy.tar.gz \
    server \
    migrations/ \
    docker-compose.yml \
    Dockerfile \
    env.example \
    nginx.conf 2>/dev/null || true
```

#### Passo 3: Enviar para VM

```bash
# Enviar pacote
gcloud compute scp terafy-deploy.tar.gz terafy-freetier-vm:~/

# Conectar na VM
gcloud compute ssh terafy-freetier-vm
```

#### Passo 4: Na VM - Deploy

**Opção A: Script Automatizado (Recomendado)**

```bash
# Na VM - Primeira vez: criar diretório e extrair
mkdir -p ~/terafy-deploy
cd ~/terafy-deploy
tar -xzf ~/terafy-deploy.tar.gz

# Copiar script de atualização (opcional, mas útil)
# Ou criar manualmente o conteúdo de update-binario.sh

# Executar atualização
./update-binario.sh
```

**Opção B: Manual**

```bash
# Na VM
cd ~

# Criar diretório e extrair
mkdir -p terafy-deploy
cd terafy-deploy
tar -xzf ~/terafy-deploy.tar.gz

# Configurar .env (se necessário)
cp env.example .env
nano .env  # Ajustar valores

# Build da imagem (só copia o binário, muito rápido!)
docker compose build server

# Iniciar serviços
docker compose up -d

# Verificar
docker compose ps
curl http://localhost:8080/ping
```

## 🔄 Atualização Rápida

Para atualizar apenas o servidor:

```bash
# Local: Recompilar e enviar
cd /Users/marcio.padovani/Projetos/ScoreGame/terafy/docker
./build-and-deploy.sh terafy-freetier-vm

# Na VM: Atualizar (usando script)
cd ~/terafy-deploy
./update-binario.sh

# Ou manualmente:
cd ~/terafy-deploy
tar -xzf ~/terafy-deploy.tar.gz
docker compose build server
docker compose restart server
```

## 📊 Comparação

| Método | Tamanho | Tempo Build | Tempo Upload |
|--------|---------|-------------|--------------|
| **Código fonte** | ~50-200MB | 3-5 min (na VM) | 1-2 min |
| **Binário** | ~10-20MB | 30s (local) | 10-20s |

## ⚙️ Estrutura do Pacote

```
terafy-deploy.tar.gz
├── server              # Binário compilado
├── migrations/         # Arquivos SQL
├── docker-compose.yml  # Configuração Docker
├── Dockerfile          # Dockerfile runtime
├── env.example         # Template de variáveis
└── nginx.conf          # Config Nginx (opcional)
```

## 🐛 Troubleshooting

### Erro: "server: command not found"
- Verificar se o binário foi compilado corretamente
- Verificar permissões: `chmod +x server`

### Erro: "migrations não encontradas"
- Verificar se migrations foram copiadas
- Verificar volume mount no docker-compose.yml

### Binário não funciona na VM
- Verificar arquitetura (amd64 vs arm64)
- Recompilar especificando arquitetura:
  ```bash
  dart compile exe --target-os linux --target-arch x64 bin/server.dart -o server
  ```


#!/bin/bash
# Script completo: Build + Preparar pasta com tudo para VM
# Uso: ./prepare-deploy.sh [VM_NAME]
# 
# Este script:
# 1. Compila o servidor para Linux (usando Docker se no Mac)
# 2. Cria pasta completa (terafy-deploy/) com tudo que a VM precisa
# 3. Opcionalmente envia para a VM

set -e

VM_NAME=${1:-""}
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEW_DEPLOY_DIR="$PROJECT_ROOT/deploy"
BUILD_DIR="$NEW_DEPLOY_DIR/build"
DEPLOY_DIR="$NEW_DEPLOY_DIR/terafy-deploy"

# Ler versão do pubspec.yaml do server
VERSION=$(grep "^version:" "$PROJECT_ROOT/server/pubspec.yaml" | sed 's/version: //' | tr -d ' ')
if [ -z "$VERSION" ]; then
    echo "⚠️  Aviso: Não foi possível ler a versão do pubspec.yaml, usando 'unknown'"
    VERSION="unknown"
fi

PACKAGE_NAME="terafy-deploy-${VERSION}.tar.gz"

echo "🚀 Preparando deploy completo para VM..."
echo "📌 Versão: $VERSION"
echo ""

# ============================================
# PASSO 1: Build do executável Linux
# ============================================
echo "📦 PASSO 1: Compilando executável Linux..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detectado macOS - usando Docker para compilar binário Linux"
    "$NEW_DEPLOY_DIR/build-linux.sh"
else
    # Se já estiver em Linux, pode compilar diretamente
    echo "🐧 Detectado Linux - compilando diretamente"
    cd "$PROJECT_ROOT/server"
    mkdir -p "$BUILD_DIR"
    # Compilar explicitamente para Linux x64
    dart compile exe --target-os linux --target-arch x64 bin/server.dart -o "$BUILD_DIR/server"
    chmod +x "$BUILD_DIR/server"
fi

if [ ! -f "$BUILD_DIR/server" ]; then
    echo "❌ Erro: Binário não foi gerado em $BUILD_DIR/server"
    exit 1
fi

echo "✅ Executável compilado: $BUILD_DIR/server"
ls -lh "$BUILD_DIR/server"
echo ""

# ============================================
# PASSO 1.5: Build do Flutter Web
# ============================================
echo "🌐 PASSO 1.5: Compilando Flutter Web..."
APP_DIR="$PROJECT_ROOT/app"
WEB_BUILD_DIR="$APP_DIR/build/web"
SKIP_WEB=false  # Inicializar como false

if [ ! -d "$APP_DIR" ]; then
    echo "⚠️  Aviso: Pasta app/ não encontrada, pulando build do Flutter Web"
    SKIP_WEB=true
else
    cd "$APP_DIR"
    
    # Verificar se Flutter está instalado
    if ! command -v flutter &> /dev/null; then
        echo "⚠️  Aviso: Flutter não encontrado, pulando build do Flutter Web"
        SKIP_WEB=true
    else
        echo "📱 Fazendo build do Flutter Web..."
        flutter build web --release
        
        if [ ! -d "$WEB_BUILD_DIR" ]; then
            echo "⚠️  Aviso: Build do Flutter Web não gerou arquivos, pulando"
            SKIP_WEB=true
        else
            SKIP_WEB=false
            WEB_FILE_COUNT=$(find "$WEB_BUILD_DIR" -type f | wc -l | tr -d ' ')
            echo "✅ Flutter Web compilado: $WEB_FILE_COUNT arquivos em $WEB_BUILD_DIR"
        fi
    fi
fi
echo ""

# ============================================
# PASSO 2: Criar pasta completa para VM
# ============================================
echo "📁 PASSO 2: Criando pasta completa para VM..."

# Limpar pasta anterior se existir
if [ -d "$DEPLOY_DIR" ]; then
    echo "🧹 Limpando pasta anterior..."
    rm -rf "$DEPLOY_DIR"
fi

# Criar estrutura de diretórios
mkdir -p "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/migrations"
mkdir -p "$DEPLOY_DIR/functions"
mkdir -p "$DEPLOY_DIR/policies"
mkdir -p "$DEPLOY_DIR/triggers"
mkdir -p "$DEPLOY_DIR/web/app"

echo "📋 Copiando arquivos necessários..."
echo "  📍 NEW_DEPLOY_DIR: $NEW_DEPLOY_DIR"

# 1. Binário compilado
cp "$BUILD_DIR/server" "$DEPLOY_DIR/server"
chmod +x "$DEPLOY_DIR/server"
echo "  ✅ Binário: server"

# 2. Migrations
cp -r "$PROJECT_ROOT/server/db/migrations"/* "$DEPLOY_DIR/migrations/"
MIGRATION_COUNT=$(ls -1 "$DEPLOY_DIR/migrations"/*.sql 2>/dev/null | wc -l | tr -d ' ')
echo "  ✅ Migrations: $MIGRATION_COUNT arquivos"

# 3. Functions (se existir)
if [ -d "$PROJECT_ROOT/server/db/functions" ] && [ "$(ls -A "$PROJECT_ROOT/server/db/functions" 2>/dev/null)" ]; then
    cp -r "$PROJECT_ROOT/server/db/functions"/* "$DEPLOY_DIR/functions/"
    FUNCTION_COUNT=$(ls -1 "$DEPLOY_DIR/functions"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ Functions: $FUNCTION_COUNT arquivos"
fi

# 4. Triggers (se existir)
if [ -d "$PROJECT_ROOT/server/db/triggers" ] && [ "$(ls -A "$PROJECT_ROOT/server/db/triggers" 2>/dev/null)" ]; then
    cp -r "$PROJECT_ROOT/server/db/triggers"/* "$DEPLOY_DIR/triggers/"
    TRIGGER_COUNT=$(ls -1 "$DEPLOY_DIR/triggers"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ Triggers: $TRIGGER_COUNT arquivos"
fi

# 5. Policies (se existir)
if [ -d "$PROJECT_ROOT/server/db/policies" ] && [ "$(ls -A "$PROJECT_ROOT/server/db/policies" 2>/dev/null)" ]; then
    cp -r "$PROJECT_ROOT/server/db/policies"/* "$DEPLOY_DIR/policies/"
    POLICY_COUNT=$(ls -1 "$DEPLOY_DIR/policies"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ Policies: $POLICY_COUNT arquivos"
fi

# 6. Docker Compose (runtime)
cp "$NEW_DEPLOY_DIR/docker-compose.runtime.yml" "$DEPLOY_DIR/docker-compose.yml"
echo "  ✅ Docker Compose: docker-compose.yml"

# 7. Dockerfile (runtime)
cp "$NEW_DEPLOY_DIR/Dockerfile.runtime" "$DEPLOY_DIR/Dockerfile"
echo "  ✅ Dockerfile: Dockerfile"

# 8. env.example
cp "$NEW_DEPLOY_DIR/env.example" "$DEPLOY_DIR/env.example"
echo "  ✅ Template de variáveis: env.example"

# 9. nginx.conf (opcional, mas útil)
cp "$NEW_DEPLOY_DIR/nginx.conf" "$DEPLOY_DIR/nginx.conf"
echo "  ✅ Nginx config: nginx.conf"

# 9.1. nginx.conf.temp (para obtenção inicial de certificados)
if [ -f "$NEW_DEPLOY_DIR/nginx.conf.temp" ]; then
    cp "$NEW_DEPLOY_DIR/nginx.conf.temp" "$DEPLOY_DIR/nginx.conf.temp"
    echo "  ✅ Nginx config temporário: nginx.conf.temp"
fi

# 10. Script de atualização (útil na VM)
cp "$NEW_DEPLOY_DIR/update-binario.sh" "$DEPLOY_DIR/update-binario.sh"
chmod +x "$DEPLOY_DIR/update-binario.sh"
echo "  ✅ Script de atualização: update-binario.sh"

# 10.1. Scripts de HTTPS (Certbot)
echo "  📋 Copiando scripts de HTTPS..."
for script in obter-certificados.sh renovar-certificados.sh certbot-renew.sh; do
    if [ -f "$NEW_DEPLOY_DIR/$script" ]; then
        cp "$NEW_DEPLOY_DIR/$script" "$DEPLOY_DIR/$script"
        chmod +x "$DEPLOY_DIR/$script"
        echo "  ✅ Script HTTPS: $script"
    else
        echo "  ⚠️  Script HTTPS não encontrado: $script (em $NEW_DEPLOY_DIR)"
    fi
done

# 11. Flutter Web (se build foi feito)
if [ "$SKIP_WEB" != "true" ] && [ -d "$WEB_BUILD_DIR" ]; then
    echo "📱 Copiando Flutter Web..."
    cp -r "$WEB_BUILD_DIR"/* "$DEPLOY_DIR/web/app/"
    WEB_FILE_COUNT=$(find "$DEPLOY_DIR/web/app" -type f | wc -l | tr -d ' ')
    echo "  ✅ Flutter Web: $WEB_FILE_COUNT arquivos em web/app/"
else
    echo "  ⚠️  Flutter Web: não incluído (build não disponível)"
fi

# 8. README para a VM (opcional, mas útil)
cat > "$DEPLOY_DIR/README.md" << 'EOF'
# Terafy Server - Deploy Package

Esta pasta contém tudo necessário para rodar o servidor Terafy na VM.

## 📁 Estrutura

- `server` - Binário compilado do servidor
- `migrations/` - Arquivos SQL de migrations
- `functions/` - Arquivos SQL de functions do PostgreSQL
- `triggers/` - Arquivos SQL de triggers do PostgreSQL
- `policies/` - Arquivos SQL de policies (RLS) do PostgreSQL
- `docker-compose.yml` - Configuração Docker Compose
- `Dockerfile` - Dockerfile para runtime
- `env.example` - Template de variáveis de ambiente
- `nginx.conf` - Configuração do Nginx (opcional)
- `update-binario.sh` - Script para atualizar o servidor

## 🚀 Primeira Instalação

1. **Configurar variáveis de ambiente:**
   ```bash
   cp env.example .env
   nano .env  # Editar com os valores corretos
   ```

2. **Iniciar serviços:**
   ```bash
   docker compose build server
   docker compose up -d
   ```

3. **Verificar status:**
   ```bash
   docker compose ps
   curl http://localhost:8080/ping
   ```

## 🔄 Atualização

Para atualizar o servidor após receber novo pacote:

```bash
./update-binario.sh
```

Ou manualmente:

```bash
# Parar containers
docker compose down

# Extrair novo pacote (se recebeu tar.gz)
tar -xzf ~/terafy-deploy.tar.gz

# Rebuild e iniciar
docker compose build server
docker compose up -d
```

## 📝 Comandos Úteis

```bash
# Ver logs
docker compose logs -f server

# Reiniciar servidor
docker compose restart server

# Ver status
docker compose ps

# Conectar ao banco
docker compose exec postgres_db psql -U postgres -d terafy_db
```
EOF
echo "  ✅ README: README.md"

echo ""
echo "✅ Pasta completa criada em: $DEPLOY_DIR"
echo ""

# Mostrar estrutura
echo "📂 Estrutura da pasta:"
if command -v tree &> /dev/null; then
    tree -L 2 "$DEPLOY_DIR" 2>/dev/null || find "$DEPLOY_DIR" -maxdepth 2 | sort
else
    find "$DEPLOY_DIR" -maxdepth 2 -type f -o -type d | sort
fi

# Calcular tamanho
TOTAL_SIZE=$(du -sh "$DEPLOY_DIR" | cut -f1)
echo ""
echo "📊 Tamanho total: $TOTAL_SIZE"

# ============================================
# PASSO 3: Criar pacote tar.gz
# ============================================
echo ""
echo "📦 PASSO 3: Criando pacote tar.gz..."

# Limpar arquivos ._* (metadados do macOS) antes de criar o tar
echo "🧹 Limpando arquivos de metadados do macOS..."
find "$DEPLOY_DIR" -name "._*" -type f -delete 2>/dev/null || true
find "$DEPLOY_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true

# Garantir permissões corretas em todos os arquivos
echo "🔐 Ajustando permissões..."
chmod -R u+rw "$DEPLOY_DIR" 2>/dev/null || true
chmod -R go+r "$DEPLOY_DIR" 2>/dev/null || true
chmod +x "$DEPLOY_DIR/server" 2>/dev/null || true
chmod +x "$DEPLOY_DIR/update-binario.sh" 2>/dev/null || true
find "$DEPLOY_DIR/migrations" -type f -exec chmod 644 {} \; 2>/dev/null || true
find "$DEPLOY_DIR/functions" -type f -exec chmod 644 {} \; 2>/dev/null || true
find "$DEPLOY_DIR/triggers" -type f -exec chmod 644 {} \; 2>/dev/null || true
find "$DEPLOY_DIR/policies" -type f -exec chmod 644 {} \; 2>/dev/null || true

cd "$NEW_DEPLOY_DIR"
# Criar tar excluindo arquivos ._* e .DS_Store, preservando permissões
# COPYFILE_DISABLE=1 no Mac evita criar arquivos ._* automaticamente
if [[ "$OSTYPE" == "darwin"* ]]; then
    COPYFILE_DISABLE=1 tar --exclude='._*' --exclude='.DS_Store' --numeric-owner -czf "$PACKAGE_NAME" -C terafy-deploy . 2>/dev/null
else
    tar --exclude='._*' --exclude='.DS_Store' --numeric-owner -czf "$PACKAGE_NAME" -C terafy-deploy . 2>/dev/null
fi

# Verificar se o tar foi criado com sucesso
if [ ! -f "$PACKAGE_NAME" ]; then
    echo "❌ Erro: Falha ao criar o pacote"
    exit 1
fi

PACKAGE_SIZE=$(du -sh "$PACKAGE_NAME" | cut -f1)
echo "✅ Pacote criado: $PACKAGE_NAME ($PACKAGE_SIZE)"
ls -lh "$PACKAGE_NAME"
echo ""

# ============================================
# PASSO 4: Enviar para VM (se especificado)
# ============================================
if [ -n "$VM_NAME" ]; then
    echo "🚀 PASSO 4: Enviando para VM: $VM_NAME"
    
    # Enviar pacote
    gcloud compute scp "$PACKAGE_NAME" "$VM_NAME:~/"
    echo "✅ Pacote enviado: $PACKAGE_NAME"
    
    # Enviar script update-binario.sh para a raiz da VM
    gcloud compute scp "$NEW_DEPLOY_DIR/update-binario.sh" "$VM_NAME:~/"
    echo "✅ Script enviado: update-binario.sh"
    
    echo ""
    echo "✅ Tudo enviado para a VM!"
    echo ""
    echo "📝 Próximos passos na VM:"
    echo "   1. Conecte: make gcloud"
    echo "   2. Execute: ./update-binario.sh"
    echo ""
    echo "   O script já está em ~/ e vai:"
    echo "   - Fazer backup"
    echo "   - Extrair o pacote $PACKAGE_NAME"
    echo "   - Atualizar e reiniciar os serviços"
else
    echo "ℹ️  VM não especificada. Para enviar, execute:"
    echo "   gcloud compute scp $NEW_DEPLOY_DIR/$PACKAGE_NAME VM_NAME:~/"
    echo ""
    echo "📁 Pasta local disponível em: $DEPLOY_DIR"
    echo "📦 Pacote disponível em: $NEW_DEPLOY_DIR/$PACKAGE_NAME"
fi

echo ""
echo "✅ Processo concluído com sucesso!"


#!/bin/bash
# Script para atualizar o servidor na VM usando binário pré-compilado
# Uso: Colocar na VM em ~/terafy-deploy/ e executar após receber terafy-deploy.tar.gz

set -e

DEPLOY_DIR="$HOME/terafy-deploy"
BACKUP_DIR="$HOME/terafy-deploy-backups"

echo "🔄 Atualizando servidor com binário pré-compilado..."
echo ""

# 1. Criar backup
if [ -d "$DEPLOY_DIR" ]; then
    echo "📦 Criando backup..."
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$BACKUP_NAME"
    echo "✅ Backup criado: $BACKUP_DIR/$BACKUP_NAME"
fi

# 2. Parar apenas o container do servidor (mantém PostgreSQL e Nginx rodando)
echo ""
echo "🛑 Parando container do servidor..."
cd "$DEPLOY_DIR" 2>/dev/null || true
# Parar apenas o servidor, mantendo PostgreSQL e Nginx
if [ -f "$DEPLOY_DIR/docker-compose.yml" ]; then
    docker compose stop server 2>/dev/null || true
    docker compose rm -f server 2>/dev/null || true
fi
# Remover container do servidor manualmente se ainda existir
docker rm -f terafy_server 2>/dev/null || true

# 3. Extrair novo pacote
echo ""
echo "📦 Extraindo novo pacote..."

# Buscar arquivo com versão (terafy-deploy-*.tar.gz) ou usar o nome antigo
PACKAGE_FILE=$(ls -t ~/terafy-deploy-*.tar.gz 2>/dev/null | head -1)
if [ -z "$PACKAGE_FILE" ]; then
    # Tentar nome antigo para compatibilidade
    if [ -f ~/terafy-deploy.tar.gz ]; then
        PACKAGE_FILE="$HOME/terafy-deploy.tar.gz"
    else
        echo "❌ Erro: Nenhum pacote terafy-deploy encontrado em ~/"
        echo "   Procurei por: terafy-deploy-*.tar.gz ou terafy-deploy.tar.gz"
        echo "   Execute: gcloud compute scp terafy-deploy-VERSION.tar.gz VM_NAME:~/"
        exit 1
    fi
fi

echo "📦 Usando pacote: $(basename "$PACKAGE_FILE")"

# Garantir que o diretório existe (sem tentar mudar permissões do diretório)
mkdir -p "$DEPLOY_DIR" 2>/dev/null || {
    echo "❌ Erro: Não foi possível criar/acessar o diretório $DEPLOY_DIR"
    echo "   Verifique as permissões do diretório"
    exit 1
}

# Limpar conteúdo antigo (mas manter o diretório)
if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]; then
    echo "🧹 Limpando conteúdo antigo..."
    rm -rf "$DEPLOY_DIR"/* 2>/dev/null || true
    rm -rf "$DEPLOY_DIR"/.[!.]* 2>/dev/null || true  # Remove arquivos ocultos exceto . e ..
fi

# Extrair pacote ignorando arquivos ._* e .DS_Store
# Usar --no-same-owner para evitar problemas de permissão entre Mac e Linux
cd "$DEPLOY_DIR" || {
    echo "❌ Erro: Não foi possível acessar o diretório $DEPLOY_DIR"
    exit 1
}

# Extrair ignorando erros de arquivos ._* (metadados do macOS)
# Usar uma abordagem que permite erros não críticos mas continua extraindo
echo "📦 Extraindo arquivos..."

# Tentar extração com exclusão de arquivos ._*
set +e  # Permitir erros temporariamente
tar --exclude='._*' --exclude='.DS_Store' --no-same-owner -xzf "$PACKAGE_FILE" 2>/tmp/tar_errors.log
TAR_EXIT=$?
set -e  # Voltar a tratar erros como críticos

# Filtrar apenas erros críticos (ignorar erros de ._*)
if [ -f /tmp/tar_errors.log ]; then
    CRITICAL_ERRORS=$(grep -vE "(Cannot open: Permission denied|Ignoring unknown extended header|Cannot utime: Operation not permitted|Exiting with failure)" /tmp/tar_errors.log || true)
    rm -f /tmp/tar_errors.log
    if [ -n "$CRITICAL_ERRORS" ]; then
        echo "⚠️  Aviso: Alguns erros durante extração (arquivos ._* podem ser ignorados)"
    fi
fi

# Verificar se os arquivos essenciais foram extraídos
ESSENTIAL_FILES=("server" "docker-compose.yml" "Dockerfile")
MISSING_FILES=()

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$DEPLOY_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

# Se faltam arquivos essenciais, tentar extração sem exclusões
if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "⚠️  Alguns arquivos essenciais não foram extraídos: ${MISSING_FILES[*]}"
    echo "🔄 Tentando extração completa (ignorando arquivos ._*)..."
    set +e
    tar --no-same-owner -xzf "$PACKAGE_FILE" 2>/dev/null
    set -e
    
    # Verificar novamente
    for file in "${ESSENTIAL_FILES[@]}"; do
        if [ ! -f "$DEPLOY_DIR/$file" ]; then
            echo "❌ Erro: Arquivo essencial não encontrado após extração: $file"
            echo "   Verifique se o pacote está completo e as permissões do diretório"
            exit 1
        fi
    done
    echo "✅ Arquivos essenciais extraídos com sucesso"
fi

# Garantir permissões corretas apenas nos arquivos extraídos (não no diretório)
if [ -f "$DEPLOY_DIR/server" ]; then
    chmod +x "$DEPLOY_DIR/server" 2>/dev/null || true
fi
if [ -f "$DEPLOY_DIR/update-binario.sh" ]; then
    chmod +x "$DEPLOY_DIR/update-binario.sh" 2>/dev/null || true
fi
# Ajustar permissões dos arquivos (não recursivo para não mexer no diretório)
find "$DEPLOY_DIR" -maxdepth 1 -type f -exec chmod u+w {} \; 2>/dev/null || true
find "$DEPLOY_DIR/migrations" -type f -exec chmod 644 {} \; 2>/dev/null || true

echo "✅ Pacote extraído"

# 4. Copiar .env de ~/ para a pasta de deploy
echo ""
echo "📋 Copiando .env de ~/ para pasta de deploy..."
if [ -f "$HOME/.env" ]; then
    cp "$HOME/.env" "$DEPLOY_DIR/.env"
    echo "✅ Arquivo .env copiado de ~/.env para $DEPLOY_DIR/.env"
else
    echo "⚠️  Arquivo .env não encontrado em ~/"
    if [ -f "$DEPLOY_DIR/env.example" ]; then
        echo "📋 Copiando de env.example..."
        cp "$DEPLOY_DIR/env.example" "$DEPLOY_DIR/.env"
        echo "📝 Edite o .env com os valores corretos antes de continuar!"
        echo "   nano $DEPLOY_DIR/.env"
        echo ""
        echo "💡 Depois, copie para ~/.env para manter sincronizado:"
        echo "   cp $DEPLOY_DIR/.env ~/.env"
        read -p "Pressione Enter após editar o .env..."
        # Perguntar se quer copiar para ~/
        read -p "Deseja copiar o .env para ~/.env agora? (s/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            cp "$DEPLOY_DIR/.env" "$HOME/.env"
            echo "✅ Arquivo .env copiado para ~/.env"
        fi
    else
        echo "❌ Erro: Arquivo env.example não encontrado!"
        echo "   Crie um arquivo .env em ~/ e execute o script novamente."
        exit 1
    fi
fi

# 5. Build da imagem (só copia binário, muito rápido!)
echo ""
echo "🔨 Construindo imagem Docker..."
docker compose build server

# 6. Iniciar apenas o servidor (PostgreSQL e Nginx já estão rodando)
echo ""
echo "🚀 Iniciando servidor (PostgreSQL e Nginx já estão rodando)..."
docker compose up -d server

# 6.5. Recriar Nginx (para montar volume do Flutter Web corretamente)
echo ""
echo "🔄 Recriando Nginx (para montar volume do Flutter Web)..."
# Parar e remover o container atual para garantir que o volume seja montado
docker compose stop nginx 2>/dev/null || true
docker compose rm -f nginx 2>/dev/null || true
# Recriar o container com o volume montado
docker compose --profile with-nginx up -d nginx
echo "✅ Nginx recriado com volume montado"

# 7. Verificar status
echo ""
echo "📊 Status dos containers:"
docker compose ps

# 8. Testar servidor
echo ""
echo "🧪 Testando servidor..."
sleep 3
if curl -f http://localhost:8080/ping > /dev/null 2>&1; then
    echo "✅ Servidor respondendo na porta 8080!"
else
    echo "⚠️  Servidor pode não estar respondendo na porta 8080. Verifique os logs:"
    echo "   docker compose logs server"
fi

# Testar Nginx também
if curl -f http://localhost/ping > /dev/null 2>&1; then
    echo "✅ Nginx respondendo na porta 80!"
else
    echo "⚠️  Nginx pode não estar respondendo. Verifique os logs:"
    echo "   docker compose logs nginx"
fi

echo ""
echo "✅ Atualização concluída!"
echo ""
echo "📝 Comandos úteis:"
echo "   docker compose logs -f server    # Ver logs do servidor"
echo "   docker compose logs -f nginx     # Ver logs do Nginx"
echo "   docker compose restart server   # Reiniciar servidor"
echo "   docker compose restart nginx    # Reiniciar Nginx"
echo "   docker compose ps                # Ver status de todos os containers"


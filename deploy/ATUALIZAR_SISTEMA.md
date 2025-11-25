# 🔄 Como Atualizar o Sistema na VM

Guia completo para atualizar o código do servidor na VM do Google Cloud.

## 🚀 Métodos de Deploy

### Método 1: Binário Pré-compilado (RECOMENDADO - Mais Rápido) ⚡

Compila localmente e envia apenas o binário. **Muito mais rápido!**

📖 **[DEPLOY_BINARIO.md](./DEPLOY_BINARIO.md)** - Guia completo

**Resumo rápido:**
```bash
# Local: Compilar e enviar
cd docker
./build-and-deploy.sh terafy-freetier-vm

# Na VM: Deploy rápido
cd ~/terafy-deploy
docker compose build server
docker compose restart server
```

### Método 2: Código Fonte (Tradicional)

Envia código fonte e compila na VM (mais lento, mas mais flexível).

## 📋 Procedimento de Atualização

### Passo Simplificado 
```bash

cd /Users/marcio.padovani/Projetos/ScoreGame && \
tar --exclude='app' --exclude='docs' --exclude='.vscode' --exclude='build' --exclude='.git' --exclude='*.md' -czf terafy.tar.gz terafy/ && \
gcloud compute scp terafy.tar.gz terafy-freetier-vm:~/ && \
gcloud compute ssh terafy-freetier-vm

```

### Passo simplificado na maquina do google
```bash
cp -r terafy terafy_backup_$(date +%Y%m%d_%H%M%S)

```

### Passo 1: Na sua máquina local - Preparar o código

```bash
# 1. Ir para o diretório do projeto
cd /Users/marcio.padovani/Projetos/ScoreGame

# 2. Comprimir o código (excluindo app, build, .git, etc)
tar --exclude='app' --exclude='docs' --exclude='.vscode' --exclude='build' --exclude='.git' --exclude='*.md' -czf terafy.tar.gz terafy/

# 3. Verificar tamanho
ls -lh terafy.tar.gz
```

### Passo 2: Upload para a VM

```bash
# Copiar arquivo para a VM
gcloud compute scp terafy.tar.gz terafy-freetier-vm:~/ 

# Conectar na VM
gcloud compute ssh terafy-freetier-vm
```

### Passo 3: Na VM - Atualizar o código

```bash
# 1. Fazer backup do código atual (opcional mas recomendado)
if [ -d terafy ]; then
    cp -r terafy terafy_backup_$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado"
fi

# 2. Parar containers antes de atualizar (evita conflitos)
cd ~/terafy/docker 2>/dev/null || true
docker compose stop server 2>/dev/null || true

# 3. Remover pasta antiga (garante limpeza completa - IMPORTANTE!)
cd ~
rm -rf terafy

# 4. Extrair o novo código
tar -xzf terafy.tar.gz

# 3. Ir para o diretório docker
cd ~/terafy/docker
```

### Passo 4: Parar os serviços (opcional - pode fazer rolling update)

```bash
# Opção A: Parar apenas o servidor (recomendado - mantém banco rodando)
docker compose stop server

# Opção B: Parar tudo (se precisar atualizar docker-compose.yml também)
# docker compose down
```

### Passo 5: Rebuild e reiniciar

```bash
# 1. Rebuild da imagem do servidor
docker compose build server

# 2. Iniciar o servidor
docker compose up -d server

# OU se parou tudo:
# docker compose up -d
```

### Passo 6: Verificar se está funcionando

```bash
# 1. Verificar status dos containers
docker compose ps

# 2. Ver logs do servidor
docker compose logs -f server

# 3. Testar endpoint
curl http://localhost:8080/ping
# Deve retornar: pong

# 4. Se estiver usando Nginx
curl http://localhost/ping
```

### Passo 7: Migrations automáticas ✅

**Não é necessário executar migrations manualmente!** 

O servidor executa migrations automaticamente na inicialização:
- Verifica quais migrations já foram executadas
- Executa apenas as migrations pendentes
- Se houver erro, o servidor não inicia (verifique os logs)

**Verificar logs das migrations:**
```bash
# Ver logs do servidor para confirmar execução das migrations
docker compose logs server | grep -i migration

# Deve mostrar algo como:
# 🔄 Verificando migrations pendentes...
# ✅ Migrations verificadas com sucesso
```

## 🔄 Atualização Rápida (Script)

Crie um script `update.sh` na VM para facilitar:

```bash
# Na VM, criar script
cd ~/terafy/docker
cat > update.sh << 'EOF'
#!/bin/bash
set -e

echo "🔄 Atualizando sistema..."

# Backup opcional
read -p "Fazer backup? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    cd ~
    if [ -d terafy ]; then
        cp -r terafy terafy_backup_$(date +%Y%m%d_%H%M%S)
        echo "✅ Backup criado"
    fi
fi

# Parar containers antes de atualizar
cd ~/terafy/docker 2>/dev/null || true
if [ -f docker-compose.yml ]; then
    echo "🛑 Parando containers..."
    docker compose stop server 2>/dev/null || true
fi

# Remover pasta antiga (garante limpeza)
cd ~
if [ -d terafy ]; then
    echo "🗑️  Removendo código antigo..."
    rm -rf terafy
fi

# Extrair novo código
if [ -f terafy.tar.gz ]; then
    echo "📦 Extraindo novo código..."
    tar -xzf terafy.tar.gz
else
    echo "❌ Arquivo terafy.tar.gz não encontrado!"
    exit 1
fi

# Rebuild e restart
cd ~/terafy/docker
echo "🔨 Rebuild do servidor..."
docker compose build server

echo "🚀 Reiniciando servidor..."
docker compose stop server
docker compose up -d server

echo "⏳ Aguardando servidor iniciar..."
sleep 5

echo "✅ Verificando status..."
docker compose ps

echo "🧪 Testando servidor..."
if curl -s http://localhost:8080/ping | grep -q "pong"; then
    echo "✅ Servidor está funcionando!"
else
    echo "❌ Servidor não respondeu. Verifique os logs:"
    echo "   docker compose logs server"
fi
EOF

chmod +x update.sh
```

**Usar o script:**
```bash
# Na VM
cd ~/terafy/docker
./update.sh
```

## 🛠️ Comandos Úteis Durante Atualização

### Ver logs em tempo real
```bash
docker compose logs -f server
```

### Verificar se há erros
```bash
docker compose ps
docker compose logs server | tail -50
```

### Rollback (voltar versão anterior)
```bash
# Se fez backup, pode restaurar
cd ~
rm -rf terafy
tar -xzf terafy_backup_YYYYMMDD_HHMMSS.tar.gz  # Use o backup mais recente
cd terafy/docker
docker compose up -d
```

### Limpar cache do Docker (se necessário)
```bash
# Limpar imagens antigas
docker image prune -a

# Limpar tudo (cuidado!)
docker system prune -a
```

## ⚠️ Checklist de Atualização

- [ ] Backup do código atual (opcional mas recomendado)
- [ ] Código atualizado na VM
- [ ] Rebuild da imagem do servidor
- [ ] Servidor reiniciado
- [ ] Teste do endpoint `/ping`
- [ ] Verificação dos logs (incluindo logs de migrations)
- [ ] Migrations executadas automaticamente (verificar logs)
- [ ] Teste funcional básico

## 🐛 Troubleshooting

### Servidor não inicia após update
```bash
# Ver logs detalhados
docker compose logs server

# Verificar se há erros de compilação
docker compose build server --no-cache

# Verificar variáveis de ambiente
docker compose exec server env | grep -E "DB_|JWT_"
```

### Erro de conexão com banco
```bash
# Verificar se PostgreSQL está rodando
docker compose ps postgres_db

# Testar conexão
docker compose exec postgres_db psql -U postgres -d terafy_db -c "SELECT 1;"
```

### Rollback rápido
```bash
# Parar servidor atual
docker compose stop server

# Usar imagem anterior (se ainda estiver no cache)
docker compose up -d server

# OU restaurar backup
cd ~
rm -rf terafy
tar -xzf terafy_backup_YYYYMMDD_HHMMSS.tar.gz
cd terafy/docker
docker compose up -d
```



curl -s http://35.224.10.2:8080/ping
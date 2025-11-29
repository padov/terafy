# 🐛 Troubleshooting - Erro 500 em app.terafy.app.br

## 🔍 Diagnóstico Rápido

Execute na VM:

```bash
cd ~/terafy-deploy
./diagnostico-nginx.sh
```

Ou da sua máquina:

```bash
cd deploy
make diagnose
```

## 🔴 Problema Mais Comum: Arquivos do Flutter Web Não Existem

O erro 500 geralmente acontece porque o Nginx não encontra os arquivos em `/usr/share/nginx/html/app/`.

### Verificar na VM:

```bash
cd ~/terafy-deploy

# Verificar se a pasta existe
ls -la web/app/

# Se não existir ou estiver vazia:
ls -la web/app/ | head -10
```

### Solução 1: Arquivos não foram incluídos no deploy

Se a pasta `web/app/` não existe ou está vazia:

1. **Na sua máquina, fazer build completo:**
   ```bash
   cd deploy
   make build
   ```

2. **Verificar se os arquivos foram gerados:**
   ```bash
   ls -la terafy-deploy/web/app/
   ```

3. **Se os arquivos existem localmente mas não na VM:**
   - O pacote foi gerado antes do build do web
   - Refazer o build e deploy:
   ```bash
   make build
   make deploy
   ```

4. **Na VM, extrair novamente:**
   ```bash
   cd ~/terafy-deploy
   ./update-binario.sh
   ```

### Solução 2: Volume não está montado

Verificar se o volume está configurado no `docker-compose.yml`:

```bash
cd ~/terafy-deploy
grep -A 5 "volumes:" docker-compose.yml
```

Deve ter:
```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
  - ./web/app:/usr/share/nginx/html/app:ro
```

Se não tiver, adicionar e reiniciar:

```bash
# Editar docker-compose.yml
nano docker-compose.yml

# Adicionar a linha do volume (se não existir)
# - ./web/app:/usr/share/nginx/html/app:ro

# Reiniciar Nginx
docker compose restart nginx
```

### Solução 3: Arquivos existem mas Nginx não acessa

Verificar permissões:

```bash
cd ~/terafy-deploy

# Verificar permissões
ls -la web/app/

# Ajustar permissões se necessário
chmod -R 755 web/app/
chown -R $(whoami):$(whoami) web/app/
```

## 📋 Checklist de Verificação

Execute na VM:

```bash
cd ~/terafy-deploy

# 1. Verificar se pasta existe
[ -d "web/app" ] && echo "✅ Pasta existe" || echo "❌ Pasta não existe"

# 2. Verificar se index.html existe
[ -f "web/app/index.html" ] && echo "✅ index.html existe" || echo "❌ index.html não existe"

# 3. Verificar volume no docker-compose
grep -q "web/app:/usr/share/nginx/html/app" docker-compose.yml && echo "✅ Volume configurado" || echo "❌ Volume não configurado"

# 4. Verificar se arquivos estão no container
docker compose exec nginx ls -la /usr/share/nginx/html/app/ 2>/dev/null && echo "✅ Arquivos no container" || echo "❌ Arquivos não estão no container"

# 5. Ver logs do Nginx
docker compose logs nginx --tail=20 | grep -i error
```

## 🔧 Solução Manual (Se Nada Funcionar)

Se os arquivos não foram incluídos no pacote, você pode copiar manualmente:

### Na sua máquina:

```bash
cd app
flutter build web --release

# Criar tar.gz do build web
cd build
tar -czf web-app.tar.gz web/
```

### Na VM:

```bash
# Receber arquivo (da sua máquina)
# gcloud compute scp app/build/web-app.tar.gz VM_NAME:~/terafy-deploy/

# Na VM, extrair
cd ~/terafy-deploy
mkdir -p web/app
tar -xzf web-app.tar.gz
mv web/* web/app/
rm -rf web-app.tar.gz

# Reiniciar Nginx
docker compose restart nginx
```

## 📊 Verificar Logs do Nginx

```bash
# Ver logs de erro
docker compose logs nginx | grep -i error

# Ver logs completos
docker compose logs nginx --tail=50

# Ver logs em tempo real
docker compose logs -f nginx
```

## ✅ Verificação Final

Após corrigir, testar:

```bash
# Na VM
curl -I http://app.terafy.app.br

# Deve retornar HTTP 200, não 500
```

## 💡 Prevenção

Para evitar esse problema no futuro:

1. **Sempre fazer `make build` completo** (inclui servidor + web)
2. **Verificar se `terafy-deploy/web/app/` tem arquivos** antes de fazer deploy
3. **Usar `make all`** que faz build + deploy automaticamente


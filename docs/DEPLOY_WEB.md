# 🌐 Guia de Deploy - Flutter Web

Este documento explica como fazer deploy do Flutter Web para `app.terafy.app.br`.

## 📋 Estrutura de Domínios

| Domínio | Destino | Status |
|---------|---------|--------|
| `api.terafy.app.br` | API Backend (porta 8080) | ✅ Configurado |
| `app.terafy.app.br` | Flutter Web App (porta 80) | ⏳ Aguardando deploy |
| `www.terafy.app.br` | Site Institucional (porta 80) | 🚧 Em construção |

## 🚀 Deploy do Flutter Web

### Passo 1: Build do Flutter Web

Na sua máquina local:

```bash
cd app

# Build para produção
flutter build web --release

# Verificar se os arquivos foram gerados
ls -la build/web/
```

Os arquivos estarão em `app/build/web/`.

### Passo 2: Preparar Arquivos para VM

Crie uma estrutura de pastas na VM para organizar os arquivos:

```bash
# Na VM, criar estrutura
mkdir -p ~/terafy-deploy/web/app
```

### Passo 3: Copiar Arquivos para VM

```bash
# Da sua máquina, copiar build/web para VM
gcloud compute scp --recurse app/build/web/* terafy-freetier-vm:~/terafy-deploy/web/app/
```

Ou, se preferir criar um tar.gz:

```bash
# Na sua máquina
cd app/build
tar -czf web-app.tar.gz web/
gcloud compute scp web-app.tar.gz terafy-freetier-vm:~/terafy-deploy/

# Na VM
cd ~/terafy-deploy
tar -xzf web-app.tar.gz
mv web web-temp
mkdir -p web/app
mv web-temp/* web/app/
rm -rf web-temp web-app.tar.gz
```

### Passo 4: Atualizar Docker Compose

Na VM, edite o `docker-compose.yml`:

```bash
cd ~/terafy-deploy
nano docker-compose.yml
```

Descomente a linha do volume do Flutter Web:

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
  - ./web/app:/usr/share/nginx/html/app:ro  # Descomente esta linha
```

### Passo 5: Reiniciar Nginx

```bash
# Reiniciar apenas o Nginx (servidor continua rodando)
docker compose restart nginx

# Ou recarregar configuração sem reiniciar
docker compose exec nginx nginx -s reload
```

### Passo 6: Verificar

```bash
# Testar se o Flutter Web está acessível
curl -I http://app.terafy.app.br

# Ou testar localmente na VM
curl -I http://localhost
```

## 🔧 Configuração Atual do Nginx

O Nginx está configurado para:

- **api.terafy.app.br**: Proxy reverso para `server:8080`
- **app.terafy.app.br**: Serve arquivos estáticos de `/usr/share/nginx/html/app`
- **www.terafy.app.br**: Retorna 503 (em construção) - pode ser atualizado depois

## 📝 Estrutura de Pastas na VM

```
~/terafy-deploy/
├── server              # Binário do servidor
├── docker-compose.yml  # Configuração Docker
├── nginx.conf          # Configuração do Nginx
├── web/
│   └── app/            # Arquivos do Flutter Web (app/build/web)
│       ├── index.html
│       ├── main.dart.js
│       └── ...
└── ...
```

## 🔄 Atualização do Flutter Web

Para atualizar o Flutter Web após fazer mudanças:

1. **Build local:**
   ```bash
   cd app
   flutter build web --release
   ```

2. **Copiar para VM:**
   ```bash
   gcloud compute scp --recurse app/build/web/* terafy-freetier-vm:~/terafy-deploy/web/app/
   ```

3. **Reiniciar Nginx:**
   ```bash
   # Na VM
   docker compose restart nginx
   ```

## 🎯 Próximos Passos

1. ✅ Configuração do Nginx - **Feito**
2. ⏳ Deploy do Flutter Web - **Aguardando**
3. 🚧 Site Institucional - **Futuro**

## 📌 Notas

- O Flutter Web usa roteamento SPA (Single Page Application), por isso o `try_files` no Nginx inclui fallback para `index.html`
- Cache de assets estáticos está configurado para 1 ano
- Headers de segurança estão configurados para todos os domínios


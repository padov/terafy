# 🧪 Guia de Teste Local

Este guia explica como testar o deploy localmente antes de enviar para a VM.

## 🚀 Teste Rápido

```bash
# Na pasta deploy/
make test-local
```

Isso vai:
1. Fazer build do servidor e Flutter Web
2. Preparar a pasta `terafy-deploy/`
3. Iniciar Docker Compose localmente
4. Mostrar URLs para testar

## 📋 Passo a Passo Manual

### 1. Build e Preparar

```bash
cd deploy
make build
```

Isso cria a pasta `terafy-deploy/` com tudo necessário.

### 2. Configurar Variáveis de Ambiente

```bash
cd terafy-deploy
cp env.example .env
nano .env  # Ajustar valores se necessário
```

### 3. Iniciar Serviços

```bash
# Build da imagem do servidor
docker compose build server

# Iniciar todos os serviços (PostgreSQL, Server, Nginx)
docker compose --profile with-nginx up -d

# Ver logs
docker compose logs -f
```

### 4. Testar

#### API (via Nginx)
```bash
# Testar API através do Nginx (simula api.terafy.app.br)
curl http://localhost/ping

# Ou diretamente no servidor
curl http://localhost:8080/ping
```

#### Flutter Web (via Nginx)
```bash
# Abrir no navegador
open http://localhost
```

**Nota:** Como estamos usando `localhost`, o Nginx vai servir o primeiro `server` block que corresponder. Para testar os domínios específicos, veja a seção "Testar com Domínios" abaixo.

### 5. Parar Serviços

```bash
docker compose down
```

## 🌐 Testar com Domínios (Simular Produção)

Para testar exatamente como será em produção (com domínios), você precisa configurar `/etc/hosts`:

### 1. Editar /etc/hosts

```bash
sudo nano /etc/hosts
```

Adicionar:
```
127.0.0.1 api.terafy.app.br
127.0.0.1 app.terafy.app.br
127.0.0.1 www.terafy.app.br
127.0.0.1 terafy.app.br
```

### 2. Testar Domínios

```bash
# API
curl http://api.terafy.app.br/ping

# Flutter Web
open http://app.terafy.app.br

# Site Institucional (deve retornar 503)
curl http://www.terafy.app.br
```

## 🔍 Verificar Logs

```bash
# Logs do servidor
docker compose logs -f server

# Logs do Nginx
docker compose logs -f nginx

# Logs do PostgreSQL
docker compose logs -f postgres_db

# Todos os logs
docker compose logs -f
```

## 🧹 Limpar Teste Local

```bash
# Parar e remover containers
docker compose down

# Remover volumes (apaga dados do banco!)
docker compose down -v

# Limpar build
cd ..
make clean
```

## 📊 Estrutura Local

```
deploy/
├── terafy-deploy/          # Pasta gerada pelo build
│   ├── server              # Binário compilado
│   ├── web/
│   │   └── app/            # Flutter Web
│   ├── docker-compose.yml  # Usado localmente
│   ├── nginx.conf
│   └── ...
└── ...
```

## ⚠️ Diferenças entre Local e Produção

| Aspecto | Local | Produção |
|---------|-------|----------|
| Domínios | localhost ou /etc/hosts | DNS real (terafy.app.br) |
| Porta API | 8080 (direto) ou 80 (via Nginx) | 80 (via Nginx) |
| Volume DB | Volume Docker local | Volume Docker na VM |
| SSL/HTTPS | Não configurado | Pode configurar depois |

## 🐛 Troubleshooting

### Nginx não inicia
```bash
# Verificar se a porta 80 está livre
lsof -i :80

# Se estiver ocupada, mudar no docker-compose.yml:
# ports:
#   - '8080:80'  # Usar porta 8080 ao invés de 80
```

### Flutter Web não aparece
```bash
# Verificar se os arquivos existem
ls -la terafy-deploy/web/app/

# Se não existir, fazer build do web:
make build-web
# E copiar manualmente:
cp -r ../app/build/web/* terafy-deploy/web/app/
```

### Servidor não conecta no banco
```bash
# Verificar se PostgreSQL está rodando
docker compose ps

# Ver logs do PostgreSQL
docker compose logs postgres_db

# Verificar variáveis de ambiente
docker compose exec server env | grep DB_
```

## ✅ Checklist de Teste

- [ ] Servidor responde em `http://localhost:8080/ping`
- [ ] API funciona via Nginx em `http://localhost/ping` (se configurado)
- [ ] Flutter Web carrega em `http://localhost` ou `http://app.terafy.app.br`
- [ ] Nginx está servindo arquivos estáticos corretamente
- [ ] Logs não mostram erros críticos


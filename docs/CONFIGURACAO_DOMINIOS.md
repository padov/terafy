# 🌐 Configuração de Domínios - Resumo

## 📊 Mapeamento de Domínios

```
┌─────────────────────────┬──────────┬─────────────────────────────┐
│ Domínio                 │ Porta    │ Destino                     │
├─────────────────────────┼──────────┼─────────────────────────────┤
│ api.terafy.app.br       │ 80       │ API Backend (proxy → 8080)  │
│ app.terafy.app.br       │ 80       │ Flutter Web App (estático)  │
│ www.terafy.app.br       │ 80       │ Site Institucional (futuro) │
│ terafy.app.br           │ 80       │ Site Institucional (futuro) │
└─────────────────────────┴──────────┴─────────────────────────────┘
```

## 🔄 Fluxo de Requisições

### API (api.terafy.app.br)
```
Cliente → Nginx:80 → Proxy → Servidor Dart:8080
```

### Flutter Web (app.terafy.app.br)
```
Cliente → Nginx:80 → Arquivos Estáticos (/usr/share/nginx/html/app)
```

### Site Institucional (www.terafy.app.br)
```
Cliente → Nginx:80 → 503 (em construção) → Futuro: Arquivos Estáticos
```

## ✅ O que foi configurado

1. **Nginx** (`deploy/nginx.conf`):
   - ✅ `api.terafy.app.br` → Proxy para backend
   - ✅ `app.terafy.app.br` → Serve Flutter Web
   - ✅ `www.terafy.app.br` → Preparado para site institucional (retorna 503 por enquanto)

2. **Docker Compose** (`deploy/docker-compose.runtime.yml`):
   - ✅ Volume do Nginx configurado
   - ✅ Comentários para montar Flutter Web quando estiver pronto

3. **Scripts de Deploy**:
   - ✅ `prepare-deploy.sh` copia `nginx.conf` para o pacote
   - ✅ `update-binario.sh` atualiza apenas o servidor (mantém Nginx rodando)

## 📝 Próximos Passos

1. **Fazer deploy do Flutter Web:**
   - Build: `flutter build web --release`
   - Copiar para VM: `~/terafy-deploy/web/app/`
   - Atualizar docker-compose para montar volume
   - Reiniciar Nginx

2. **Configurar DNS (quando estiver pronto):**
   - Criar registros A no registro.br
   - Aguardar propagação DNS

3. **Site Institucional (futuro):**
   - Quando estiver pronto, atualizar nginx.conf
   - Montar volume em `./web/www`

## 🔧 Arquivos Modificados

- `deploy/nginx.conf` - Configuração do Nginx com 3 blocos server
- `deploy/docker-compose.runtime.yml` - Volume preparado para Flutter Web
- `deploy/DEPLOY_WEB.md` - Guia de deploy do Flutter Web (novo)
- `deploy/CONFIGURACAO_DOMINIOS.md` - Este arquivo (novo)


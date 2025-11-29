# ⚡ Teste Rápido Local

## 🚀 Comando Único

```bash
cd deploy
make test-local
```

Isso faz tudo automaticamente:
1. ✅ Build do servidor
2. ✅ Build do Flutter Web
3. ✅ Prepara pasta terafy-deploy/
4. ✅ Inicia Docker Compose
5. ✅ Mostra URLs para testar

## 🧪 Testar

Depois de executar `make test-local`, você pode testar:

### No Navegador:
- **Flutter Web**: http://localhost
- **API Health**: http://localhost/ping

### No Terminal:
```bash
# API direta (porta 8080)
curl http://localhost:8080/ping

# API via Nginx (porta 80)
curl http://localhost/ping

# Flutter Web
curl http://localhost
```

## 📊 Ver Logs

```bash
cd terafy-deploy
docker compose logs -f
```

## 🛑 Parar

```bash
cd terafy-deploy
docker compose down
```

## 💡 Dica: Testar com Domínios

Para testar exatamente como em produção:

1. Editar `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   ```

2. Adicionar:
   ```
   127.0.0.1 api.terafy.app.br
   127.0.0.1 app.terafy.app.br
   ```

3. Testar:
   ```bash
   curl http://api.terafy.app.br/ping
   open http://app.terafy.app.br
   ```

## 🐛 Problemas?

Ver `TESTE_LOCAL.md` para troubleshooting completo.


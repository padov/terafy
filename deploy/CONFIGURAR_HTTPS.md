# 🔐 Configuração de HTTPS com Let's Encrypt

Este guia explica como configurar HTTPS para os domínios do Terafy usando certificados SSL gratuitos do Let's Encrypt.

## 📋 Pré-requisitos

1. ✅ DNS configurado e propagado (verifique com `dig api.terafy.app.br`)
2. ✅ Nginx rodando na VM
3. ✅ Portas 80 e 443 abertas no firewall do GCP
4. ✅ Docker e Docker Compose instalados na VM

## 🚀 Passo a Passo

### 1. Verificar DNS

Antes de obter os certificados, verifique se os domínios estão apontando para o IP da VM:

```bash
# Na sua máquina local
dig api.terafy.app.br
dig app.terafy.app.br
dig www.terafy.app.br
```

Todos devem retornar o mesmo IP da sua VM do Google Cloud.

### 2. Fazer Deploy com HTTPS

Na sua máquina local:

```bash
cd deploy
make build
make deploy
```

### 3. Conectar na VM

```bash
make gcloud
# ou
gcloud compute ssh terafy-freetier-vm
```

### 4. Atualizar o Servidor

Na VM:

```bash
cd ~/terafy-deploy
./update-binario.sh
```

Isso vai:
- Atualizar o código
- Recriar o Nginx com suporte a HTTPS
- Criar os volumes do Certbot

### 5. Obter Certificados SSL

Na VM, execute o script para obter os certificados:

```bash
cd ~/terafy-deploy
chmod +x obter-certificados.sh
./obter-certificados.sh
```

**Importante:** O script vai solicitar um email. Você pode definir antes:

```bash
export CERTBOT_EMAIL=seu-email@exemplo.com
./obter-certificados.sh
```

O script vai:
1. Verificar se o Nginx está rodando
2. Obter certificados para cada domínio:
   - `api.terafy.app.br`
   - `app.terafy.app.br`
   - `www.terafy.app.br`
   - `terafy.app.br`
3. Recarregar o Nginx para usar os certificados

### 6. Verificar se Funcionou

Teste os certificados:

```bash
# Testar API
curl -I https://api.terafy.app.br/ping

# Testar Flutter Web
curl -I https://app.terafy.app.br

# Verificar certificado
openssl s_client -connect api.terafy.app.br:443 -servername api.terafy.app.br < /dev/null
```

No navegador, acesse:
- `https://api.terafy.app.br/ping`
- `https://app.terafy.app.br`

Você deve ver o cadeado verde indicando que o certificado está válido.

## 🔄 Renovação Automática

Os certificados do Let's Encrypt expiram a cada 90 dias. Configure renovação automática:

### Opção 1: Cron Job (Recomendado)

Na VM, adicione ao crontab:

```bash
crontab -e
```

Adicione esta linha (renova duas vezes por dia):

```cron
0 3,15 * * * /home/marcio.padovani/terafy-deploy/certbot-renew.sh >> /var/log/certbot-renew.log 2>&1
```

### Opção 2: Systemd Timer (Alternativa)

Crie um arquivo `/etc/systemd/system/certbot-renew.service`:

```ini
[Unit]
Description=Renew Let's Encrypt certificates
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=marcio.padovani
WorkingDirectory=/home/marcio.padovani/terafy-deploy
ExecStart=/home/marcio.padovani/terafy-deploy/certbot-renew.sh
```

E um timer `/etc/systemd/system/certbot-renew.timer`:

```ini
[Unit]
Description=Renew Let's Encrypt certificates twice daily

[Timer]
OnCalendar=*-*-* 03,15:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Ative o timer:

```bash
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer
```

## 🛠️ Comandos Úteis

### Verificar Certificados

```bash
# Listar certificados
docker compose exec certbot certbot certificates

# Ver detalhes de um certificado
docker compose exec certbot ls -la /etc/letsencrypt/live/api.terafy.app.br/
```

### Renovar Manualmente

```bash
cd ~/terafy-deploy
./renovar-certificados.sh
```

### Forçar Renovação

```bash
docker compose run --rm certbot certonly --force-renewal -d api.terafy.app.br
docker compose exec nginx nginx -s reload
```

### Ver Logs do Certbot

```bash
docker compose logs certbot
```

## 🐛 Troubleshooting

### Erro: "Failed to obtain certificate"

**Causa:** DNS não está propagado ou Nginx não está acessível na porta 80.

**Solução:**
1. Verifique o DNS: `dig api.terafy.app.br`
2. Verifique se a porta 80 está aberta no firewall do GCP
3. Verifique se o Nginx está rodando: `docker compose ps`

### Erro: "Connection refused" ao acessar HTTPS

**Causa:** Certificados não foram obtidos ou Nginx não foi recarregado.

**Solução:**
1. Verifique se os certificados existem:
   ```bash
   docker compose exec nginx ls -la /etc/letsencrypt/live/
   ```
2. Recarregue o Nginx:
   ```bash
   docker compose exec nginx nginx -s reload
   ```

### Erro: "Certificate has expired"

**Causa:** Certificado expirou e não foi renovado.

**Solução:**
1. Renove manualmente:
   ```bash
   ./renovar-certificados.sh
   ```
2. Verifique o cron job se estiver configurado

### Nginx não inicia após obter certificados

**Causa:** Certificados não foram encontrados ou caminho incorreto.

**Solução:**
1. Verifique os logs: `docker compose logs nginx`
2. Verifique se os certificados existem:
   ```bash
   docker compose exec certbot ls -la /etc/letsencrypt/live/
   ```
3. Verifique o `nginx.conf` se os caminhos estão corretos

## 📝 Estrutura de Arquivos

```
~/terafy-deploy/
├── nginx.conf                    # Configuração do Nginx com HTTPS
├── docker-compose.yml            # Inclui serviço Certbot
├── obter-certificados.sh         # Script para obter certificados inicialmente
├── renovar-certificados.sh       # Script para renovar manualmente
└── certbot-renew.sh              # Script para renovação automática (cron)
```

## 🔒 Segurança

A configuração inclui:

- ✅ **TLS 1.2 e 1.3** apenas
- ✅ **Cipher suites modernos** e seguros
- ✅ **HSTS (HTTP Strict Transport Security)** - força HTTPS
- ✅ **OCSP Stapling** - melhora performance e privacidade
- ✅ **Redirecionamento HTTP → HTTPS** automático

## 📚 Referências

- [Let's Encrypt](https://letsencrypt.org/)
- [Certbot Documentation](https://certbot.eff.org/)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [SSL Labs Test](https://www.ssllabs.com/ssltest/) - Teste a segurança do seu SSL

## ✅ Checklist

- [ ] DNS configurado e propagado
- [ ] Portas 80 e 443 abertas no firewall
- [ ] Nginx rodando na VM
- [ ] Certificados obtidos com sucesso
- [ ] HTTPS funcionando em todos os domínios
- [ ] Renovação automática configurada
- [ ] Testado no navegador (cadeado verde)


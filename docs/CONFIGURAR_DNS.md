# 📋 Guia de Configuração DNS - registro.br

Este guia explica como configurar os domínios no registro.br para o Terafy.

## 🌐 Domínios a Configurar

- **www.terafy.app.br** → porta 80 (Flutter Web)
- **terafy.app.br** → porta 80 (Flutter Web)
- **api.terafy.app.br** → porta 8080 (API Backend)
- **app.terafy.app.br** → porta 80 (Flutter Web)

## 📝 Passo a Passo

### 1. Obter IP Estático no Google Cloud

```bash
# Criar IP estático (se ainda não criou)
gcloud compute addresses create terafy-static-ip --region=us-central1

# Ver o IP estático
gcloud compute addresses describe terafy-static-ip --region=us-central1 --format='get(address)'
```

**Anote o IP retornado!** (ex: `34.29.65.82`)

### 2. Atribuir IP Estático à VM

```bash
# Parar VM
gcloud compute instances stop terafy-freetier-vm --zone=us-central1-b

# Remover IP temporário
gcloud compute instances delete-access-config terafy-freetier-vm \
  --zone=us-central1-b \
  --access-config-name="External NAT"

# Adicionar IP estático (substitua SEU_IP_ESTATICO pelo IP obtido)
gcloud compute instances add-access-config terafy-freetier-vm \
  --zone=us-central1-b \
  --address=SEU_IP_ESTATICO \
  --access-config-name="External NAT"

# Iniciar VM
gcloud compute instances start terafy-freetier-vm --zone=us-central1-b
```

### 3. Configurar DNS no registro.br

1. Acesse: https://registro.br
2. Faça login e vá em **"Meus Domínios"**
3. Selecione **terafy.app.br**
4. Clique em **"MODO AVANÇADO"**

#### 3.1. Criar Registros A

No modo avançado, crie os seguintes registros **Tipo A**:

| Tipo | Nome | Valor | TTL |
|------|------|-------|-----|
| A | `@` | `SEU_IP_ESTATICO` | 3600 |
| A | `www` | `SEU_IP_ESTATICO` | 3600 |
| A | `api` | `SEU_IP_ESTATICO` | 3600 |
| A | `app` | `SEU_IP_ESTATICO` | 3600 |

**Exemplo:**
- **Tipo:** A
- **Nome:** `www` (ou `api`, `app`, ou `@` para o domínio raiz)
- **Valor:** `34.29.65.82` (seu IP estático)
- **TTL:** `3600` (ou deixe padrão)

#### 3.2. Aguardar Propagação DNS

O registro.br mostrará uma mensagem:
> "No momento, os servidores DNS do domínio se encontram em transição. Servidores DNS externos poderão ser delegados em seu domínio em aproximadamente X horas"

**Aguarde a transição terminar** (geralmente 2-4 horas).

### 4. Verificar Propagação DNS

Após a transição, verifique se o DNS está propagado:

```bash
# Verificar cada domínio
dig www.terafy.app.br +short
dig terafy.app.br +short
dig api.terafy.app.br +short
dig app.terafy.app.br +short

# Todos devem retornar o mesmo IP estático
```

Ou use `nslookup`:

```bash
nslookup www.terafy.app.br
nslookup terafy.app.br
nslookup api.terafy.app.br
nslookup app.terafy.app.br
```

### 5. Testar Acesso

```bash
# Testar API
curl -I http://api.terafy.app.br/ping

# Testar Flutter Web (quando deploy estiver feito)
curl -I http://www.terafy.app.br
curl -I http://terafy.app.br
curl -I http://app.terafy.app.br
```

## 🔧 Configuração do Nginx

O Nginx já está configurado para rotear os domínios corretamente:

- **api.terafy.app.br** → proxy reverso para servidor Dart (porta 8080)
- **www.terafy.app.br** → serve arquivos estáticos do Flutter Web
- **terafy.app.br** → serve arquivos estáticos do Flutter Web
- **app.terafy.app.br** → serve arquivos estáticos do Flutter Web

A configuração está em `docker/nginx.conf`.

## 📌 Notas Importantes

1. **IP Estático**: Use sempre o mesmo IP estático para todos os registros A
2. **Propagação**: DNS pode levar até 48 horas para propagar completamente
3. **TTL**: Use TTL de 3600 (1 hora) para mudanças mais rápidas
4. **Firewall**: Certifique-se de que as portas 80 e 443 estão abertas no firewall do GCloud

## 🔒 Próximos Passos (Opcional)

Depois de configurar DNS, você pode:

1. **Configurar HTTPS** com Let's Encrypt (certbot)
2. **Adicionar redirecionamento** de HTTP para HTTPS
3. **Configurar CORS** no backend para aceitar requisições dos domínios


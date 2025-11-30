# Evolution API - Ambiente de Teste

Este diretório contém a configuração Docker para testar o Evolution API localmente.

## Pré-requisitos

- Docker
- Docker Compose

## Configuração Rápida

### Opção 1: Usando o script helper (Recomendado)

```bash
# Tornar o script executável (apenas primeira vez)
chmod +x docker/evolution-api.sh

# Iniciar o Evolution API
cd docker
./evolution-api.sh start

# Ver logs
./evolution-api.sh logs

# Ver todos os comandos disponíveis
./evolution-api.sh help
```

### Opção 2: Usando docker-compose diretamente

#### 1. Configurar variáveis de ambiente (opcional)

```bash
# Copie o arquivo de exemplo
cp evolution-api.env.example evolution-api.env

# Edite e ajuste as variáveis conforme necessário
# O mais importante é a EVOLUTION_API_KEY
```

#### 2. Iniciar o Evolution API

```bash
# Iniciar em background
docker-compose -f docker-compose.evolution-api.yml up -d

# Ver logs
docker-compose -f docker-compose.evolution-api.yml logs -f

# Parar
docker-compose -f docker-compose.evolution-api.yml down
```

### 3. Verificar se está rodando

```bash
# Verificar saúde do serviço
curl http://localhost:8080/health

# Ou acesse no navegador
open http://localhost:8080
```

## Criar Instância WhatsApp

### Usando o script helper (Recomendado)

```bash
# Criar instância
./evolution-api.sh create-instance

# Obter QR Code para conectar
./evolution-api.sh connect

# Listar instâncias
./evolution-api.sh instances
```

### Usando curl diretamente

#### 1. Criar instância

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: terafy-test-key-change-me" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "terafy-instance",
    "token": "terafy-token",
    "qrcode": true
  }'
```

#### 2. Obter QR Code

```bash
# Obter QR Code para conectar WhatsApp
curl http://localhost:8080/instance/connect/terafy-instance \
  -H "apikey: terafy-test-key-change-me"
```

Ou acesse no navegador:
```
http://localhost:8080/instance/connect/terafy-instance?apikey=terafy-test-key-change-me
```

#### 3. Verificar status da instância

```bash
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: terafy-test-key-change-me"
```

## Configurar Webhook

O webhook já está configurado no `docker-compose.evolution-api.yml` para apontar para:
```
http://host.docker.internal:8080/whatsapp/webhook
```

Isso permite que o Evolution API (rodando no Docker) se comunique com o servidor Terafy (rodando no host).

**Nota**: Se o servidor Terafy estiver rodando em outra porta ou URL, ajuste a variável `WEBHOOK_GLOBAL_URL` no docker-compose.

## Testar Envio de Mensagem

### Usando o script helper

```bash
# Enviar mensagem de teste (apenas número, sem @s.whatsapp.net)
./evolution-api.sh send-test 5511999999999
```

### Usando curl diretamente

```bash
curl -X POST http://localhost:8080/message/sendText/terafy-instance \
  -H "apikey: terafy-test-key-change-me" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999@s.whatsapp.net",
    "text": "Teste de mensagem do Terafy"
  }'
```

## Configuração no Terafy

Adicione as seguintes variáveis no `.env` do servidor Terafy:

```env
# Evolution API
WHATSAPP_API_URL=http://localhost:8080
WHATSAPP_API_KEY=terafy-test-key-change-me
WHATSAPP_INSTANCE_NAME=terafy-instance

# Configurações
WHATSAPP_REMINDER_DAYS=1
WHATSAPP_CONVERSATION_TIMEOUT=600
PRODUCTION=false
```

## Estrutura de Arquivos

```
docker/
├── docker-compose.evolution-api.yml  # Docker Compose para Evolution API
├── evolution-api.env.example         # Exemplo de variáveis de ambiente
├── evolution-api.sh                  # Script helper para gerenciar o Evolution API
└── README.evolution-api.md           # Este arquivo
```

## Comandos Úteis

### Usando o script helper

```bash
# Ver logs em tempo real
./evolution-api.sh logs

# Reiniciar o serviço
./evolution-api.sh restart

# Ver status
./evolution-api.sh status

# Acessar shell do container
./evolution-api.sh shell

# Limpar tudo (containers e volumes)
./evolution-api.sh clean
```

### Usando docker-compose diretamente

```bash
# Ver logs em tempo real
docker-compose -f docker-compose.evolution-api.yml logs -f evolution-api

# Reiniciar o serviço
docker-compose -f docker-compose.evolution-api.yml restart evolution-api

# Parar e remover volumes (limpar dados)
docker-compose -f docker-compose.evolution-api.yml down -v

# Ver status dos containers
docker-compose -f docker-compose.evolution-api.yml ps

# Acessar shell do container
docker exec -it evolution-api-test sh
```

## Troubleshooting

### Porta 8080 já está em uso

Se a porta 8080 já estiver em uso (por exemplo, pelo servidor Terafy), altere a porta no `docker-compose.evolution-api.yml`:

```yaml
ports:
  - "8081:8080"  # Use 8081 no host, 8080 no container
```

E ajuste a `WHATSAPP_API_URL` no `.env` do Terafy:
```env
WHATSAPP_API_URL=http://localhost:8081
```

### Webhook não está funcionando

1. Verifique se o servidor Terafy está rodando
2. Verifique se a URL do webhook está correta
3. Em alguns sistemas, `host.docker.internal` pode não funcionar. Tente:
   - Linux: Use o IP da interface Docker (geralmente `172.17.0.1`)
   - Mac/Windows: `host.docker.internal` deve funcionar

### Instância não conecta

1. Verifique os logs: `docker-compose -f docker-compose.evolution-api.yml logs evolution-api`
2. Certifique-se de que o QR Code foi escaneado corretamente
3. Verifique se o número de WhatsApp está ativo

## Limpeza

Para remover tudo (containers, volumes, redes):

```bash
docker-compose -f docker-compose.evolution-api.yml down -v
```

## Próximos Passos

1. Configure o Evolution API conforme acima
2. Crie uma instância e conecte seu WhatsApp Business
3. Configure as variáveis de ambiente no Terafy
4. Teste o envio de mensagens
5. Configure o webhook para receber mensagens

Para mais informações, consulte a [documentação oficial do Evolution API](https://doc.evolution-api.com/).


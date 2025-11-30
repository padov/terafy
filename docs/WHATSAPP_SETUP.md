# Configuração do WhatsApp Business

## Visão Geral

O sistema de WhatsApp permite comunicação bidirecional com pacientes para agendamento de consultas e confirmações automáticas.

## Funcionalidades

### 1. Agendamento via WhatsApp
- Paciente envia mensagem para número do terapeuta
- Sistema identifica paciente pelo número de telefone
- Menu interativo com opções:
  - Agendar Consulta
  - Meus Agendamentos
  - Cancelar Agendamento
- Seleção de data e horário através de botões
- Confirmação do agendamento

### 2. Confirmação Automática
- Envio automático de lembrete com X dias de antecedência (configurável por terapeuta)
- Botões interativos para confirmar/cancelar/reagendar
- Atualização automática do status do agendamento

## Configuração

### Evolution API (Recomendado)

O sistema usa Evolution API, uma solução self-hosted para WhatsApp Business.

#### 1. Instalação do Evolution API

```bash
# Usando Docker (recomendado)
docker run -d \
  --name evolution-api \
  -p 8080:8080 \
  -e AUTHENTICATION_API_KEY=sua-chave-secreta \
  atendai/evolution-api:latest
```

#### 2. Configuração no Terafy

Adicione as seguintes variáveis no arquivo `.env`:

```env
# Evolution API
WHATSAPP_API_URL=http://localhost:8080
WHATSAPP_API_KEY=sua-chave-secreta
WHATSAPP_INSTANCE_NAME=terafy-instance

# Configurações
WHATSAPP_REMINDER_DAYS=1
WHATSAPP_CONVERSATION_TIMEOUT=600
PRODUCTION=false
```

#### 3. Criar Instância no Evolution API

Após iniciar o Evolution API, você precisa criar uma instância:

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: sua-chave-secreta" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "terafy-instance",
    "token": "seu-token-opcional",
    "qrcode": true
  }'
```

#### 4. Conectar WhatsApp

1. Acesse o QR Code gerado pela API
2. Escaneie com o WhatsApp Business que será usado
3. Aguarde a conexão ser estabelecida

#### 5. Configurar no Terafy

Cada terapeuta precisa ter sua instância WhatsApp configurada. Isso pode ser feito via API ou interface administrativa (quando implementada).

### Configuração por Terapeuta

Cada terapeuta pode configurar:
- Número de WhatsApp
- Dias de antecedência para confirmação (padrão: 1 dia)
- Habilitar/desabilitar WhatsApp

## Endpoints da API

### Webhook (Evolution API → Terafy)

```
POST /whatsapp/webhook
Content-Type: application/json

{
  "event": "messages.upsert",
  "data": {
    "messages": [...]
  }
}
```

**Nota**: Este endpoint não requer autenticação, mas deve validar a assinatura do Evolution API em produção.

### Enviar Confirmações Manualmente

```http
POST /whatsapp/confirmations
Authorization: Bearer {token}
Content-Type: application/json

{
  "therapistId": 1,
  "daysBefore": 1
}
```

## Fluxo de Agendamento

1. **Paciente envia mensagem**: "Olá, gostaria de agendar"
2. **Sistema identifica**: Busca paciente pelo número de telefone
3. **Menu interativo**: Mostra opções (Agendar, Ver Agendamentos, Cancelar)
4. **Seleção de data**: Sistema mostra próximas datas disponíveis (botões)
5. **Seleção de horário**: Sistema mostra horários disponíveis para a data escolhida
6. **Confirmação**: Sistema confirma dados e cria agendamento
7. **Mensagem de confirmação**: Envia detalhes do agendamento

## Fluxo de Confirmação Automática

1. **X dias antes do agendamento**: Sistema busca agendamentos que precisam de confirmação
2. **Envia mensagem**: WhatsApp com botões (Confirmar, Cancelar, Reagendar)
3. **Paciente responde**: Clica em um dos botões
4. **Sistema processa**: Atualiza status do agendamento conforme resposta

## Processamento Automático

Para processar confirmações automaticamente, configure um cron job:

```bash
# Executar a cada hora
0 * * * * curl -X POST http://localhost:8080/whatsapp/confirmations \
  -H "Authorization: Bearer {admin-token}" \
  -H "Content-Type: application/json" \
  -d '{"therapistId": 1, "daysBefore": 1}'
```

Ou use o endpoint `/messages/process-reminders` que processa todas as mensagens agendadas.

## Segurança

1. **Validação de Webhook**: Em produção, valide a assinatura das requisições do Evolution API
2. **RLS**: Aplicado automaticamente nas conversas via Row Level Security
3. **LGPD**: Logs de consentimento para comunicação via WhatsApp
4. **Rate Limiting**: Considere implementar limite de mensagens por paciente/hora

## Troubleshooting

### Mensagens não são recebidas
- Verifique se o Evolution API está rodando
- Confirme que a instância está conectada (status: connected)
- Verifique os logs do Evolution API

### Mensagens não são enviadas
- Verifique as variáveis de ambiente
- Confirme que `PRODUCTION=true` em produção
- Verifique os logs do servidor Terafy

### Paciente não é identificado
- Verifique se o número está cadastrado no paciente
- Confirme que o formato do número está correto
- Considere implementar código de vinculação

## Próximos Passos

- Implementar identificação por CPF ou código de vinculação
- Completar fluxo de agendamento (seleção de data/hora)
- Implementar cancelamento via WhatsApp
- Adicionar suporte a mídia (fotos, documentos)
- Dashboard de conversas WhatsApp
- Estatísticas de interações


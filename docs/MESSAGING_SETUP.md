# Configuração do Sistema de Mensagens

## Visão Geral

O sistema de mensagens permite enviar notificações através de múltiplos canais (Email, SMS, WhatsApp, Push) com suporte a templates personalizáveis.

## Variáveis de Ambiente

### Email (SMTP)

Para configurar o envio de emails, adicione as seguintes variáveis no arquivo `.env`:

```env
# Configurações SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu-email@gmail.com
SMTP_PASSWORD=sua-senha-app
SMTP_FROM_EMAIL=noreply@terafy.com
SMTP_FROM_NAME=Terafy
SMTP_USE_TLS=true

# Modo produção (quando true, tenta enviar emails reais)
PRODUCTION=false
```

### SMS (Futuro - Twilio)

```env
TWILIO_ACCOUNT_SID=seu-account-sid
TWILIO_AUTH_TOKEN=seu-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

### WhatsApp (Futuro - Twilio)

```env
TWILIO_WHATSAPP_NUMBER=whatsapp:+1234567890
```

### Push Notifications (Futuro - Firebase)

```env
FCM_SERVER_KEY=sua-chave-fcm
```

## Endpoints da API

### Enviar Mensagem Genérica

```http
POST /messages/send
Authorization: Bearer {token}
Content-Type: application/json

{
  "messageType": "general",
  "channel": "email",
  "recipientType": "patient",
  "recipientId": 123,
  "subject": "Assunto da mensagem",
  "content": "Conteúdo da mensagem",
  "metadata": {
    "recipient_email": "paciente@email.com"
  }
}
```

### Enviar Lembrete de Agendamento

```http
POST /messages/reminder
Authorization: Bearer {token}
Content-Type: application/json

{
  "appointmentId": 456,
  "patientId": 123,
  "patientName": "João Silva",
  "patientEmail": "joao@email.com",
  "patientPhone": "+5511999999999",
  "therapistId": 1,
  "therapistName": "Dr. Maria Santos",
  "appointmentDateTime": "2024-12-15T14:00:00Z",
  "durationMinutes": 50,
  "channel": "email",
  "location": "Consultório Centro",
  "onlineLink": "https://meet.google.com/abc-defg-hij"
}
```

### Buscar Histórico de Mensagens

```http
GET /messages/history?recipientType=patient&recipientId=123&status=sent&channel=email&limit=50&offset=0
Authorization: Bearer {token}
```

### Processar Lembretes Agendados (Admin)

```http
POST /messages/process-reminders
Authorization: Bearer {token}
```

Este endpoint processa todas as mensagens agendadas que devem ser enviadas. Em produção, deve ser chamado periodicamente por um cron job.

## Templates

Os templates são armazenados no banco de dados e podem ser personalizados. Variáveis disponíveis:

- `{patientName}` - Nome do paciente
- `{therapistName}` - Nome do terapeuta
- `{appointmentDate}` - Data e hora formatada do agendamento
- `{appointmentTime}` - Horário do agendamento
- `{appointmentDuration}` - Duração formatada
- `{location}` - Local do atendimento (se disponível)
- `{onlineLink}` - Link para atendimento online (se disponível)

## Canais Disponíveis

### Email ✅
- Implementado e funcional
- Requer configuração SMTP
- Em desenvolvimento, apenas loga os emails

### SMS ⏳
- Estrutura criada, aguardando implementação com Twilio

### WhatsApp ⏳
- Estrutura criada, aguardando implementação com Twilio

### Push ⏳
- Estrutura criada, aguardando implementação com FCM

## Processamento de Lembretes

Para processar lembretes automaticamente, configure um cron job que chame o endpoint `/messages/process-reminders` periodicamente (ex: a cada 5 minutos):

```bash
*/5 * * * * curl -X POST http://localhost:8080/messages/process-reminders -H "Authorization: Bearer {admin-token}"
```

Ou use um serviço de agendamento como `cron` ou `systemd timers`.

## Próximos Passos

1. Implementar envio real de SMS usando Twilio
2. Implementar envio de WhatsApp usando Twilio WhatsApp API
3. Implementar notificações push usando Firebase Cloud Messaging
4. Adicionar webhooks para status de entrega
5. Criar dashboard de estatísticas de mensagens
6. Adicionar suporte a templates HTML para emails


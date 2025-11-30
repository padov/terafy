-- migrate:up

-- Template padrão para lembrete de agendamento por email
INSERT INTO message_templates (name, type, channel, subject_template, content_template, variables, is_active, created_at, updated_at)
VALUES (
  'Lembrete de Agendamento - Email',
  'appointmentReminder',
  'email',
  'Lembrete: Consulta com {therapistName}',
  'Olá {patientName},

Este é um lembrete de que você tem uma consulta agendada:

Data e hora: {appointmentDate}
Duração: {appointmentDuration}
Terapeuta: {therapistName}
{location?Local: {location}}
{onlineLink?Link online: {onlineLink}}

Por favor, confirme sua presença ou entre em contato caso precise reagendar.

Atenciosamente,
Equipe Terafy',
  '["patientName", "therapistName", "appointmentDate", "appointmentTime", "appointmentDuration", "location", "onlineLink"]'::JSONB,
  TRUE,
  NOW(),
  NOW()
)
ON CONFLICT (type, channel) DO NOTHING;

-- Template padrão para lembrete de agendamento por SMS
INSERT INTO message_templates (name, type, channel, subject_template, content_template, variables, is_active, created_at, updated_at)
VALUES (
  'Lembrete de Agendamento - SMS',
  'appointmentReminder',
  'sms',
  '',
  'Olá {patientName}! Lembrete: consulta com {therapistName} em {appointmentDate}. Confirme sua presença.',
  '["patientName", "therapistName", "appointmentDate", "appointmentTime"]'::JSONB,
  TRUE,
  NOW(),
  NOW()
)
ON CONFLICT (type, channel) DO NOTHING;

-- Template padrão para lembrete de agendamento por WhatsApp
INSERT INTO message_templates (name, type, channel, subject_template, content_template, variables, is_active, created_at, updated_at)
VALUES (
  'Lembrete de Agendamento - WhatsApp',
  'appointmentReminder',
  'whatsapp',
  '',
  'Olá {patientName}! 👋

Este é um lembrete de que você tem uma consulta agendada:

📅 Data e hora: {appointmentDate}
⏱️ Duração: {appointmentDuration}
👨‍⚕️ Terapeuta: {therapistName}
{location?📍 Local: {location}}
{onlineLink?🔗 Link online: {onlineLink}}

Por favor, confirme sua presença ou entre em contato caso precise reagendar.

Atenciosamente,
Equipe Terafy',
  '["patientName", "therapistName", "appointmentDate", "appointmentTime", "appointmentDuration", "location", "onlineLink"]'::JSONB,
  TRUE,
  NOW(),
  NOW()
)
ON CONFLICT (type, channel) DO NOTHING;

-- migrate:down

DELETE FROM message_templates WHERE name IN (
  'Lembrete de Agendamento - Email',
  'Lembrete de Agendamento - SMS',
  'Lembrete de Agendamento - WhatsApp'
);


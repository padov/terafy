# Guia de Teste - API de Anamnese

## Pré-requisitos

1. ✅ Backend rodando em `http://localhost:8080`
2. ✅ Migrations executadas (incluindo as novas de anamnese)
3. ✅ Usuário de teste criado e logado
4. ✅ Terapeuta vinculado ao usuário
5. ✅ Paciente criado (para testar anamnese)

## 1. Autenticação

Primeiro, faça login para obter o token:

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@terafy.app.br",
    "password": "senha123"
  }'
```

**Resposta esperada:**

```json
{
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "teste@terafy.app.br",
    "role": "therapist",
    ...
  }
}
```

**Guarde o `auth_token` para usar nas próximas requisições!**

---

## 2. Criar um Paciente (se ainda não tiver)

Antes de criar uma anamnese, você precisa de um paciente:

```bash
TOKEN="seu_token_aqui"

curl -X POST http://localhost:8080/patients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "fullName": "João Silva",
    "phone": "11999999999",
    "email": "joao@example.com",
    "birthDate": "1990-01-15"
  }'
```

**Guarde o `id` do paciente retornado!**

---

## 3. Testar Endpoints de Templates

### 3.1 Listar Templates

```bash
TOKEN="seu_token_aqui"

curl -X GET "http://localhost:8080/anamnesis/templates" \
  -H "Authorization: Bearer $TOKEN"
```

**Com filtros:**

```bash
# Filtrar por categoria
curl -X GET "http://localhost:8080/anamnesis/templates?category=adult" \
  -H "Authorization: Bearer $TOKEN"

# Filtrar por terapeuta (admin)
curl -X GET "http://localhost:8080/anamnesis/templates?therapistId=1" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.2 Criar Template Personalizado

```bash
TOKEN="seu_token_aqui"

curl -X POST http://localhost:8080/anamnesis/templates \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Anamnese Personalizada - TCC",
    "description": "Template focado em Terapia Cognitivo-Comportamental",
    "category": "adult",
    "isDefault": false,
    "structure": {
      "version": "1.0",
      "metadata": {
        "name": "Anamnese Personalizada - TCC",
        "category": "adult"
      },
      "sections": [
        {
          "id": "chief_complaint",
          "title": "Queixa Principal",
          "order": 1,
          "fields": [
            {
              "id": "description",
              "type": "textarea",
              "label": "Descrição da Queixa",
              "required": true,
              "order": 1,
              "placeholder": "Descreva o motivo da consulta..."
            },
            {
              "id": "intensity",
              "type": "slider",
              "label": "Intensidade (0-10)",
              "required": false,
              "order": 2,
              "min": 0,
              "max": 10,
              "default_value": 5
            }
          ]
        }
      ],
      "settings": {
        "allow_patient_fill": false,
        "require_completion": true,
        "show_progress": true
      }
    }
  }'
```

**Resposta esperada:**

```json
{
  "id": 1,
  "therapistId": 1,
  "name": "Anamnese Personalizada - TCC",
  "description": "Template focado em Terapia Cognitivo-Comportamental",
  "category": "adult",
  "isDefault": false,
  "isSystem": false,
  "structure": { ... },
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

### 3.3 Buscar Template por ID

```bash
TOKEN="seu_token_aqui"
TEMPLATE_ID=1

curl -X GET "http://localhost:8080/anamnesis/templates/$TEMPLATE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.4 Atualizar Template

```bash
TOKEN="seu_token_aqui"
TEMPLATE_ID=1

curl -X PUT "http://localhost:8080/anamnesis/templates/$TEMPLATE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Anamnese Personalizada - TCC (Atualizada)",
    "description": "Template atualizado",
    "category": "adult",
    "isDefault": true,
    "structure": {
      "version": "1.0",
      "metadata": {
        "name": "Anamnese Personalizada - TCC (Atualizada)",
        "category": "adult"
      },
      "sections": [ ... ]
    }
  }'
```

### 3.5 Deletar Template

```bash
TOKEN="seu_token_aqui"
TEMPLATE_ID=1

curl -X DELETE "http://localhost:8080/anamnesis/templates/$TEMPLATE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Nota:** Templates do sistema (`isSystem: true`) não podem ser deletados.

---

## 4. Testar Endpoints de Anamnese

### 4.1 Criar Anamnese

```bash
TOKEN="seu_token_aqui"
PATIENT_ID=1
TEMPLATE_ID=1  # Opcional

curl -X POST http://localhost:8080/anamnesis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patientId": '$PATIENT_ID',
    "therapistId": 1,
    "templateId": '$TEMPLATE_ID',
    "data": {
      "chief_complaint": {
        "description": "Ansiedade e insônia há 3 meses, iniciada após mudança de trabalho",
        "intensity": 7
      },
      "demographic": {
        "naturalidade": "São Paulo",
        "nacionalidade": "Brasileira"
      },
      "medical_history": {
        "current_diseases": "Nenhuma",
        "allergies": "Poeira"
      }
    },
    "completedAt": null
  }'
```

**Resposta esperada:**

```json
{
  "id": 1,
  "patientId": 1,
  "therapistId": 1,
  "templateId": 1,
  "data": {
    "chief_complaint": {
      "description": "Ansiedade e insônia há 3 meses...",
      "intensity": 7
    },
    ...
  },
  "completedAt": null,
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

### 4.2 Buscar Anamnese por Paciente

```bash
TOKEN="seu_token_aqui"
PATIENT_ID=1

curl -X GET "http://localhost:8080/anamnesis/patient/$PATIENT_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.3 Buscar Anamnese por ID

```bash
TOKEN="seu_token_aqui"
ANAMNESIS_ID=1

curl -X GET "http://localhost:8080/anamnesis/$ANAMNESIS_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.4 Atualizar Anamnese

```bash
TOKEN="seu_token_aqui"
ANAMNESIS_ID=1

curl -X PUT "http://localhost:8080/anamnesis/$ANAMNESIS_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "data": {
      "chief_complaint": {
        "description": "Ansiedade e insônia há 3 meses, iniciada após mudança de trabalho. Sintomas pioraram nas últimas semanas.",
        "intensity": 8
      },
      "demographic": {
        "naturalidade": "São Paulo",
        "nacionalidade": "Brasileira",
        "religiao": "Católica"
      },
      "medical_history": {
        "current_diseases": "Nenhuma",
        "allergies": "Poeira, ácaros"
      },
      "psychiatric_history": {
        "previous_diagnoses": "Nenhum diagnóstico prévio",
        "current_medications": "Nenhuma medicação"
      }
    },
    "completedAt": "2025-01-15T12:00:00Z"
  }'
```

### 4.5 Marcar Anamnese como Completa

```bash
TOKEN="seu_token_aqui"
ANAMNESIS_ID=1

curl -X PUT "http://localhost:8080/anamnesis/$ANAMNESIS_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "completedAt": "2025-01-15T12:00:00Z"
  }'
```

### 4.6 Deletar Anamnese

```bash
TOKEN="seu_token_aqui"
ANAMNESIS_ID=1

curl -X DELETE "http://localhost:8080/anamnesis/$ANAMNESIS_ID" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 5. Cenários de Teste

### 5.1 Criar Anamnese Duplicada (Deve Falhar)

```bash
TOKEN="seu_token_aqui"
PATIENT_ID=1

# Primeira criação (deve funcionar)
curl -X POST http://localhost:8080/anamnesis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patientId": '$PATIENT_ID',
    "therapistId": 1,
    "data": {}
  }'

# Segunda criação (deve retornar erro 409)
curl -X POST http://localhost:8080/anamnesis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patientId": '$PATIENT_ID',
    "therapistId": 1,
    "data": {}
  }'
```

**Resposta esperada (erro):**

```json
{
  "error": "Já existe uma anamnese para este paciente. Use a atualização."
}
```

### 5.2 Tentar Deletar Template do Sistema (Deve Falhar)

```bash
TOKEN="seu_token_aqui"
SYSTEM_TEMPLATE_ID=1  # ID de um template do sistema

curl -X DELETE "http://localhost:8080/anamnesis/templates/$SYSTEM_TEMPLATE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta esperada (erro):**

```json
{
  "error": "Não é possível deletar templates do sistema"
}
```

### 5.3 Acessar Anamnese de Outro Terapeuta (Deve Falhar)

```bash
TOKEN="seu_token_aqui"
ANAMNESIS_ID=1  # Anamnese de outro terapeuta

curl -X GET "http://localhost:8080/anamnesis/$ANAMNESIS_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta esperada:** 403 Forbidden ou 404 Not Found (dependendo da implementação RLS)

---

## 6. Script de Teste Completo

Crie um arquivo `test_anamnesis.sh`:

```bash
#!/bin/bash

# Configurações
BASE_URL="http://localhost:8080"
EMAIL="teste@terafy.app.br"
PASSWORD="senha123"

echo "🔐 Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.auth_token')
THERAPIST_ID=$(echo $LOGIN_RESPONSE | jq -r '.user.accountId // .user.id')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Erro ao fazer login"
  echo $LOGIN_RESPONSE
  exit 1
fi

echo "✅ Login realizado com sucesso"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Criar paciente
echo "👤 Criando paciente..."
PATIENT_RESPONSE=$(curl -s -X POST "$BASE_URL/patients" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "fullName": "João Silva Teste",
    "phone": "11999999999",
    "email": "joao.teste@example.com"
  }')

PATIENT_ID=$(echo $PATIENT_RESPONSE | jq -r '.id')
echo "✅ Paciente criado: ID $PATIENT_ID"
echo ""

# Criar template
echo "📋 Criando template..."
TEMPLATE_RESPONSE=$(curl -s -X POST "$BASE_URL/anamnesis/templates" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Template de Teste",
    "category": "adult",
    "structure": {
      "sections": [
        {
          "id": "test",
          "title": "Teste",
          "order": 1,
          "fields": []
        }
      ]
    }
  }')

TEMPLATE_ID=$(echo $TEMPLATE_RESPONSE | jq -r '.id')
echo "✅ Template criado: ID $TEMPLATE_ID"
echo ""

# Criar anamnese
echo "📝 Criando anamnese..."
ANAMNESIS_RESPONSE=$(curl -s -X POST "$BASE_URL/anamnesis" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"patientId\": $PATIENT_ID,
    \"therapistId\": $THERAPIST_ID,
    \"templateId\": $TEMPLATE_ID,
    \"data\": {
      \"test\": {
        \"value\": \"teste\"
      }
    }
  }")

ANAMNESIS_ID=$(echo $ANAMNESIS_RESPONSE | jq -r '.id')
echo "✅ Anamnese criada: ID $ANAMNESIS_ID"
echo ""

# Buscar anamnese
echo "🔍 Buscando anamnese..."
curl -s -X GET "$BASE_URL/anamnesis/$ANAMNESIS_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "✅ Todos os testes passaram!"
```

**Para executar:**

```bash
chmod +x test_anamnesis.sh
./test_anamnesis.sh
```

---

## 7. Verificações no Banco de Dados

### Ver templates criados:

```sql
SELECT id, name, category, is_default, is_system, therapist_id
FROM anamnesis_templates;
```

### Ver anamneses criadas:

```sql
SELECT id, patient_id, therapist_id, template_id, completed_at, created_at
FROM anamnesis;
```

### Ver dados de uma anamnese:

```sql
SELECT id, patient_id, data
FROM anamnesis
WHERE id = 1;
```

---

## 8. Troubleshooting

### Erro 401 Unauthorized

- Verifique se o token está sendo enviado no header `Authorization: Bearer <token>`
- Verifique se o token não expirou (faça login novamente)

### Erro 404 Not Found

- Verifique se o ID existe no banco de dados
- Verifique se você tem permissão para acessar o recurso (RLS)

### Erro 409 Conflict

- Anamnese duplicada para o mesmo paciente
- Template padrão duplicado para o mesmo terapeuta

### Erro 500 Internal Server Error

- Verifique os logs do servidor
- Verifique se as migrations foram executadas
- Verifique se o JSON está bem formatado

---

## 9. Próximos Passos

Após testar os endpoints:

1. ✅ Criar template padrão do sistema
2. ✅ Implementar validação de campos obrigatórios
3. ✅ Implementar campos condicionais no frontend
4. ✅ Criar interface de preenchimento de anamnese

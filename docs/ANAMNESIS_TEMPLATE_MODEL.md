# Documentação: Modelo de Template de Anamnese

## 1. Estrutura Geral do Template

O template é um objeto JSON com a seguinte estrutura:

```json
{
  "version": "1.0",
  "metadata": {
    "name": "Anamnese Padrão",
    "description": "Template completo baseado em boas práticas clínicas",
    "category": "adult",
    "created_at": "2025-01-15T10:00:00Z"
  },
  "sections": [
    // Array de seções
  ],
  "settings": {
    "allow_patient_fill": false,
    "require_completion": true,
    "show_progress": true
  }
}
```

## 2. Estrutura de Seção

```json
{
  "id": "string",              // Identificador único da seção (ex: "chief_complaint")
  "title": "string",           // Título exibido (ex: "Queixa Principal")
  "description": "string?",     // Descrição/instruções opcionais
  "order": number,             // Ordem de exibição (1, 2, 3...)
  "collapsible": boolean,       // Se pode ser colapsada (default: false)
  "collapsed_by_default": boolean, // Se inicia colapsada (default: false)
  "conditional": {             // Condição para exibir a seção (opcional)
    "field": "string",         // ID do campo que será verificado
    "operator": "string",      // Operador: "equals", "not_equals", "contains", "greater_than", "less_than", "is_empty", "is_not_empty"
    "value": any,              // Valor de comparação
    "section_id": "string?"    // Se a condição é baseada em campo de outra seção
  },
  "fields": [                  // Array de campos da seção
    // Estrutura de campo (ver abaixo)
  ]
}
```

## 3. Estrutura de Campo

### 3.1 Campos Base (Todos os Tipos)

```json
{
  "id": "string",                    // Identificador único (ex: "chief_complaint_description")
  "type": "string",                  // Tipo do campo (ver tipos abaixo)
  "label": "string",                 // Label exibido
  "description": "string?",          // Texto de ajuda/descrição
  "required": boolean,               // Se é obrigatório (default: false)
  "order": number,                   // Ordem dentro da seção
  "placeholder": "string?",          // Texto placeholder
  "default_value": any,              // Valor padrão
  "validation": {                    // Regras de validação (opcional)
    "min_length": number?,
    "max_length": number?,
    "pattern": "string?",             // Regex pattern
    "custom_message": "string?"       // Mensagem de erro customizada
  },
  "conditional": {                   // Condição para exibir o campo (opcional)
    "field": "string",
    "operator": "string",
    "value": any,
    "section_id": "string?"
  },
  "fillable_by": ["patient", "therapist"], // Quem pode preencher (default: ["therapist"])
  "sensitive": boolean,              // Se é campo sensível (default: false)
  "can_skip": boolean,               // Se paciente pode pular se desconfortável (default: false)
  "help_text": "string?"             // Texto de ajuda adicional
}
```

## 4. Tipos de Campos Disponíveis

### 4.1 `text` - Campo de Texto Simples

```json
{
  "id": "naturalidade",
  "type": "text",
  "label": "Naturalidade",
  "required": false,
  "placeholder": "Cidade onde nasceu",
  "validation": {
    "max_length": 100
  }
}
```

### 4.2 `textarea` - Campo de Texto Multilinha

```json
{
  "id": "chief_complaint",
  "type": "textarea",
  "label": "Descrição da Queixa",
  "required": true,
  "placeholder": "Descreva o motivo que trouxe você à terapia...",
  "validation": {
    "min_length": 10,
    "max_length": 2000
  },
  "rows": 4  // Número de linhas (opcional, default: 3)
}
```

### 4.3 `number` - Campo Numérico

```json
{
  "id": "age",
  "type": "number",
  "label": "Idade",
  "required": false,
  "validation": {
    "min": 0,
    "max": 150
  },
  "step": 1  // Incremento (opcional, default: 1)
}
```

### 4.4 `slider` - Controle Deslizante

```json
{
  "id": "complaint_intensity",
  "type": "slider",
  "label": "Intensidade do Desconforto",
  "required": false,
  "min": 0,
  "max": 10,
  "step": 1,
  "default_value": 5,
  "show_value": true,        // Mostrar valor atual (default: true)
  "labels": {                // Labels customizados (opcional)
    "min": "Nenhum",
    "max": "Máximo"
  }
}
```

### 4.5 `boolean` - Checkbox/Switch

```json
{
  "id": "has_suicide_attempts",
  "type": "boolean",
  "label": "Já teve tentativas de suicídio?",
  "required": false,
  "default_value": false,
  "display_as": "switch"  // "switch" ou "checkbox" (default: "switch")
}
```

### 4.6 `select` - Dropdown/Select

```json
{
  "id": "frequency",
  "type": "select",
  "label": "Frequência",
  "required": false,
  "options": [
    {"value": "daily", "label": "Diária"},
    {"value": "weekly", "label": "Semanal"},
    {"value": "monthly", "label": "Mensal"},
    {"value": "sporadic", "label": "Esporádica"}
  ],
  "multiple": false,        // Permite seleção múltipla (default: false)
  "searchable": false        // Permite busca (default: false)
}
```

### 4.7 `radio` - Botões de Opção

```json
{
  "id": "marital_status",
  "type": "radio",
  "label": "Estado Civil",
  "required": false,
  "options": [
    {"value": "single", "label": "Solteiro(a)"},
    {"value": "married", "label": "Casado(a)"},
    {"value": "divorced", "label": "Divorciado(a)"},
    {"value": "widowed", "label": "Viúvo(a)"}
  ],
  "layout": "vertical"  // "vertical" ou "horizontal" (default: "vertical")
}
```

### 4.8 `checkbox_group` - Múltipla Seleção

```json
{
  "id": "interests",
  "type": "checkbox_group",
  "label": "Interesses e Hobbies",
  "required": false,
  "options": [
    {"value": "sports", "label": "Esportes"},
    {"value": "reading", "label": "Leitura"},
    {"value": "music", "label": "Música"},
    {"value": "travel", "label": "Viagens"}
  ],
  "min_selections": 0,      // Mínimo de seleções (opcional)
  "max_selections": null    // Máximo de seleções (null = ilimitado)
}
```

### 4.9 `date` - Data

```json
{
  "id": "treatment_start",
  "type": "date",
  "label": "Data de Início do Tratamento",
  "required": false,
  "min_date": "1900-01-01",  // Data mínima (opcional)
  "max_date": null,           // Data máxima (null = hoje)
  "format": "dd/MM/yyyy"      // Formato de exibição (opcional)
}
```

### 4.10 `time` - Hora

```json
{
  "id": "preferred_time",
  "type": "time",
  "label": "Horário Preferencial",
  "required": false,
  "format": "HH:mm"  // Formato (opcional)
}
```

### 4.11 `datetime` - Data e Hora

```json
{
  "id": "last_crisis",
  "type": "datetime",
  "label": "Última Crise",
  "required": false
}
```

### 4.12 `file` - Upload de Arquivo

```json
{
  "id": "medical_report",
  "type": "file",
  "label": "Relatório Médico",
  "required": false,
  "accept": ["pdf", "jpg", "png"],  // Tipos aceitos
  "max_size": 5242880,               // Tamanho máximo em bytes (5MB)
  "multiple": false                  // Permitir múltiplos arquivos
}
```

### 4.13 `rating` - Escala de Avaliação

```json
{
  "id": "satisfaction",
  "type": "rating",
  "label": "Satisfação com o Tratamento",
  "required": false,
  "max": 5,                          // Número máximo de estrelas
  "icon": "star",                    // "star" ou "heart" (default: "star")
  "show_labels": true,               // Mostrar labels (default: false)
  "labels": ["Muito Insatisfeito", "", "", "", "Muito Satisfeito"]
}
```

### 4.14 `section_break` - Separador Visual

```json
{
  "id": "break_1",
  "type": "section_break",
  "label": "Próxima Seção",
  "style": "line"  // "line", "space", "divider" (default: "line")
}
```

## 5. Campos Condicionais

Exemplo de campo que aparece apenas se outro campo for verdadeiro:

```json
{
  "id": "suicide_attempts_details",
  "type": "textarea",
  "label": "Detalhes das Tentativas",
  "required": false,
  "conditional": {
    "field": "has_suicide_attempts",
    "operator": "equals",
    "value": true
  }
}
```

### Operadores Disponíveis:
- `equals` - Igual a
- `not_equals` - Diferente de
- `contains` - Contém (para arrays/strings)
- `greater_than` - Maior que
- `less_than` - Menor que
- `is_empty` - Está vazio
- `is_not_empty` - Não está vazio
- `in` - Está em (array de valores)

## 6. Exemplo Completo de Template

```json
{
  "version": "1.0",
  "metadata": {
    "name": "Anamnese Padrão - Adulto",
    "description": "Template completo para pacientes adultos",
    "category": "adult"
  },
  "sections": [
    {
      "id": "demographic",
      "title": "Dados Demográficos",
      "order": 1,
      "fields": [
        {
          "id": "naturalidade",
          "type": "text",
          "label": "Naturalidade",
          "required": false,
          "order": 1
        },
        {
          "id": "nacionalidade",
          "type": "text",
          "label": "Nacionalidade",
          "required": false,
          "order": 2,
          "default_value": "Brasileira"
        }
      ]
    },
    {
      "id": "chief_complaint",
      "title": "Queixa Principal",
      "order": 2,
      "fields": [
        {
          "id": "description",
          "type": "textarea",
          "label": "Descrição da Queixa",
          "required": true,
          "order": 1,
          "placeholder": "Qual o motivo que trouxe você à terapia?",
          "validation": {
            "min_length": 10,
            "max_length": 2000
          }
        },
        {
          "id": "intensity",
          "type": "slider",
          "label": "Intensidade (0-10)",
          "required": false,
          "order": 2,
          "min": 0,
          "max": 10,
          "default_value": 5,
          "show_value": true
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
```

## 7. Validação de Template

### Regras de Validação:
1. **IDs Únicos**: Todos os `id` de seções e campos devem ser únicos
2. **Ordem**: `order` deve ser sequencial e positivo
3. **Tipos**: `type` deve ser um dos tipos suportados
4. **Condicionais**: Campos referenciados em `conditional.field` devem existir
5. **Opções**: Campos `select`, `radio`, `checkbox_group` devem ter `options`
6. **Valores Numéricos**: `min` < `max` em campos numéricos/slider

## 8. Armazenamento no Banco

O template é armazenado na coluna `structure` (JSONB) da tabela `anamnesis_templates`:

```sql
structure JSONB NOT NULL DEFAULT '{}'::jsonb
```

Os dados preenchidos são armazenados na coluna `data` (JSONB) da tabela `anamnesis`:

```sql
data JSONB NOT NULL DEFAULT '{}'::jsonb
```

### Estrutura do `data`:
```json
{
  "chief_complaint": {
    "description": "Ansiedade e insônia há 3 meses...",
    "intensity": 7
  },
  "demographic": {
    "naturalidade": "São Paulo",
    "nacionalidade": "Brasileira"
  }
}
```

## 9. Funcionalidades Futuras (Paciente Preencher)

### Campos Adicionais no Template:
```json
{
  "fillable_by": ["patient", "therapist"], // Quem pode preencher
  "sensitive": boolean,                     // Campo sensível
  "can_skip": boolean                       // Paciente pode pular
}
```

### Status da Anamnese:
- `draft` - Rascunho
- `patient_pending` - Aguardando preenchimento do paciente
- `patient_completed` - Preenchida pelo paciente, aguardando revisão
- `therapist_reviewing` - Em revisão pelo terapeuta
- `completed` - Completa e validada

### Campos no Banco (Futuro):
```sql
ALTER TABLE anamnesis
ADD COLUMN filled_by VARCHAR(20) DEFAULT 'therapist', -- 'patient', 'therapist', 'both'
ADD COLUMN patient_filled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN therapist_reviewed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN status VARCHAR(20) DEFAULT 'draft';
```


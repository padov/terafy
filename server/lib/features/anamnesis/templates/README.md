# Templates de Anamnese

Este diretório contém os templates padrão de anamnese do sistema.

## Template Padrão - Adulto

O template padrão (`default_template.dart`) é um template completo baseado em boas práticas clínicas que cobre todos os aspectos fundamentais para uma avaliação inicial completa do paciente.

### Estrutura do Template

O template inclui **13 seções principais**:

1. **Dados Demográficos** - Naturalidade, nacionalidade, religião, residência, composição familiar
2. **Queixa Principal** - Descrição, quando começou, frequência, intensidade, fatores desencadeantes
3. **Histórico Médico** - Doenças, cirurgias, alergias, internações, acompanhamento médico
4. **Histórico Psiquiátrico** - Diagnósticos, tratamentos, medicações, tentativas de suicídio, uso de substâncias
5. **Histórico Familiar** - Doenças mentais, suicídio, relacionamentos familiares, dinâmica familiar
6. **Histórico de Desenvolvimento** - Gravidez, desenvolvimento motor/linguagem, marcos, escolarização
7. **Vida Social** - Círculo social, amizades, relacionamentos, rede de apoio, lazer, hobbies
8. **Vida Profissional/Acadêmica** - Ocupação, satisfação, conflitos, histórico, situação acadêmica
9. **Hábitos de Vida** - Sono, alimentação, atividade física, tecnologia, rotina diária
10. **Sexualidade** - Orientação, vida sexual, satisfação, questões relacionadas
11. **Aspectos Legais** - Processos judiciais, histórico criminal, questões de guarda
12. **Expectativas** - Expectativas do tratamento, objetivos pessoais, disponibilidade, comprometimento
13. **Observações Gerais** - Impressões do terapeuta, aspectos relevantes, notas adicionais

### Tipos de Campos Utilizados

- `text` - Campos de texto simples
- `textarea` - Campos de texto multilinha
- `select` - Dropdown com opções
- `slider` - Controle deslizante (0-10)
- `boolean` - Checkbox/Switch

### Campos Condicionais

O template inclui exemplos de campos condicionais:
- `suicide_attempts_details` - Aparece apenas se `has_suicide_attempts` for `true`

### Campos Sensíveis

Alguns campos são marcados como `sensitive: true`:
- Campos de sexualidade
- Campos de aspectos legais

Estes campos podem ter tratamento especial no frontend (avisos, opção de pular, etc.).

## Como Inserir o Template no Banco

### Opção 1: Via Script Dart (Recomendado)

```bash
make seed-anamnesis-template
# ou
cd server && dart run bin/seed_default_anamnesis_template.dart
```

### Opção 2: Via SQL

```bash
# Via psql
psql -h localhost -U postgres -d terafy_db -f server/db/scripts/seed_default_anamnesis_template.sql

# Ou via docker
docker exec -i terafy_postgres psql -U postgres -d terafy_db < server/db/scripts/seed_default_anamnesis_template.sql
```

## Verificar Template Inserido

```sql
SELECT id, name, category, is_system, is_default, created_at 
FROM anamnesis_templates 
WHERE is_system = TRUE;
```

## Características do Template Padrão

- ✅ **Template do Sistema** (`is_system: true`) - Não pode ser deletado
- ✅ **Disponível para Todos** (`therapist_id: NULL`) - Todos os terapeutas podem usar
- ✅ **Categoria: Adulto** - Focado em pacientes adultos
- ✅ **Não é Padrão por Padrão** (`is_default: false`) - Terapeuta escolhe se quer usar como padrão
- ✅ **Completo** - Cobre todos os aspectos fundamentais
- ✅ **Flexível** - Campos opcionais permitem personalização

## Personalização

Terapeutas podem:
- Usar o template padrão como está
- Duplicar e personalizar
- Criar seus próprios templates baseados no padrão
- Marcar como template padrão pessoal

## Próximos Templates

Futuramente podem ser criados:
- Template para Crianças
- Template para Casais
- Template para Famílias
- Templates por abordagem (TCC, Psicanalítica, etc.)


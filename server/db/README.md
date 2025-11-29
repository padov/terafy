# Database Structure

## Estrutura de Pastas

```
server/db/
├── migrations/           # Migrations de schema (CREATE TABLE, ALTER TABLE, etc)
├── functions/            # PostgreSQL functions (recriadas após cada migration)
├── triggers/             # PostgreSQL triggers (recriados após cada migration)
├── policies/             # RLS policies (recriadas após cada migration)
└── scripts/              # Scripts utilitários
```

## Estratégia de Organização

### Functions, Triggers e Policies

Todas as functions, triggers e policies estão centralizadas em pastas dedicadas e são **automaticamente recriadas** ao final de cada execução de migrations pelo `MigrationManager`.

#### Como Funciona:

1. **Migrations normais** criam apenas estrutura (tabelas, colunas, índices, etc)
   - ⚠️ **IMPORTANTE**: **NÃO** coloque functions, triggers ou policies dentro de migrations
   - Use as pastas dedicadas: `functions/`, `triggers/`, `policies/`
2. **Ao final das migrations**, o `MigrationManager` automaticamente:
   - Executa todos os arquivos de `functions/` (ordem alfabética)
   - Executa todos os arquivos de `triggers/` (ordem alfabética)
   - Executa todos os arquivos de `policies/` (ordem alfabética)

#### Benefícios:

- ✅ **Single Source of Truth**: Todo código em um lugar
- ✅ **Manutenção Simplificada**: Fácil encontrar e editar
- ✅ **Consistência Garantida**: Sempre recriadas, nunca desatualizadas
- ✅ **Sem Duplicação**: Não precisa manter código em múltiplas migrations
- ✅ **Refatoração Fácil**: Mudar uma function não requer nova migration

#### Estrutura dos Arquivos:

- **Functions**: Cada function em um arquivo separado (ex: `ft_after_appointment.sql`)
- **Triggers**: Agrupados por tabela (ex: `appointments_triggers.sql`)
- **Policies**: Agrupados por tabela (ex: `therapists_policies.sql`)

Todos os arquivos são idempotentes (podem ser executados múltiplas vezes sem erro).

## Documentação Adicional

- [README_FUNCTIONS_STRATEGY.md](./README_FUNCTIONS_STRATEGY.md) - Estratégia detalhada
- [EXTRACTION_COMPLETE.md](./EXTRACTION_COMPLETE.md) - Resumo da extração realizada
- [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) - Plano de implementação


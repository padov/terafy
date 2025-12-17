# Diretrizes para Geração de Changelogs

Este documento contém as diretrizes e prompts para a geração dos arquivos `CHANGELOG.md` do projeto Terafy.

## 1. Visão Geral

O projeto possui dois arquivos de changelog distintos, cada um com um público e tom de voz específicos:

| Arquivo              | Localização           | Público Alvo                 | Tom de Voz                                |
| -------------------- | --------------------- | ---------------------------- | ----------------------------------------- |
| **Server Changelog** | `server/CHANGELOG.md` | Desenvolvedores, DevOps      | Técnico, Preciso, Detalhado               |
| **App Changelog**    | `app/CHANGELOG.md`    | Terapeutas (Usuários Finais) | Comercial, Amigável, Focado em Benefícios |

---

## 2. Server Changelog (`server/CHANGELOG.md`)

**Objetivo**: Documentar mudanças técnicas, arquiteturais e de banco de dados.

**Prompt para IA**:

> "Analise o histórico de git da pasta `server/` e `common/`. Gere uma entrada para o arquivo `server/CHANGELOG.md` seguindo o padrão 'Keep a Changelog'.
>
> **Regras:**
>
> 1. Use terminologia técnica (ex: Endpoints, Migrations, Triggers, RLS, Middleware).
> 2. Documente mudanças em schemas de banco de dados.
> 3. Liste novas dependências ou refatorações importantes.
> 4. Agrupe por: 'Adicionado', 'Alterado', 'Corrigido', 'Segurança'.
> 5. Para funcionalidades visíveis, explique a implementação técnica (backend)."

**Exemplo de Item**:

- "Migrations para vincular sessões a transações financeiras (`add_transaction_fk_to_sessions`)."

---

## 3. App Changelog (`app/CHANGELOG.md`)

**Objetivo**: Comunicar valor e novas funcionalidades para o terapeuta que utiliza o aplicativo.

**Prompt para IA**:

> "Analise as features implementadas recentemente (visualize o histórico do `app/` ou o `server/CHANGELOG.md` para contexto). Gere uma entrada para o arquivo `app/CHANGELOG.md`.
>
> **Regras:**
>
> 1. **NÃO** use jargão técnico (evite: endpoint, widget, bloc, repository, migration).
> 2. Foque no **BENEFÍCIO** para o usuário. (Ex: Em vez de 'Novo endpoint de anamnese', use 'Crie anamneses completas de forma digital').
> 3. Use emojis para tornar a leitura leve.
> 4. Explique como a funcionalidade ajuda no dia a dia do consultório.
> 5. Estruture com títulos chamativos e listas de benefícios.
> 6. Seções sugeridas: '✨ Novidades', '🔧 Melhorias', '🐛 Correções'."

**Exemplo de Item**:

- "💰 **Integração Financeira Automática**: Agora suas sessões e finanças estão conectadas! Ao registrar uma sessão, o financeiro é atualizado automaticamente."

---

## 4. Processo de Atualização Recomendado

1. **Analise o Git**: Verifique os commits recentes e diffs para entender o que mudou de fato.
2. **Atualize o Server**: Comece pelo técnico para garantir que todas as implementações foram capturadas.
3. **Traduza para o App**: Use o changelog do server como base para escrever a versão comercial do app, filtrando o que é irrelevante para o usuário final (ex: refatoração interna, mudanças em testes).

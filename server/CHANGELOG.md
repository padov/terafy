# Changelog - Server

Todas as mudanças notáveis no servidor serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## 0.5.0

- Updated Anamnesis handler to support public invite context generation.
- Updated `WEB_URL` to point to the correct frontend port for local development.
- Added database migration for Anamnesis invites table.
- Added AI features (#13).
- Added Financial Transactions features (#12).

---

## [0.3.0] - 2025-12-14

### 🎉 Adicionado

#### Dashboard Financeiro na Home

- Inclusão de resumo financeiro (receita mensal) no endpoint de Home
- Integração do `HomeController` com `FinancialRepository`
- Atualização do modelo `HomeSummary` para incluir dados financeiros

#### Integração Financeira Automática

- Migrations para vincular sessões a transações financeiras (`add_transaction_fk_to_sessions`)
- Campo de preço padrão da sessão na tabela de terapeutas e modelos
- Triggers para criação automática de transação financeira ao registrar uma sessão (`ft_session_a_i_create_financial_transaction`)
- Sincronização automática de status entre Sessão e Transação

#### Refatoração de Banco de Dados

- Organização de triggers em funções SQL dedicadas e versionadas
- Novas funções de banco de dados para integridade referencial e automação

### 🔧 Alterado

- **Session Repository**: Refinamento de queries SQL para evitar ambiguidade de colunas em joins
- **Controllers e Repositories**: Atualização completa de `Financial`, `Session` e `Therapist` para suportar o novo fluxo integrado
- **Testes**: Atualização de testes de integração e unitários para refletir as novas regras de negócio financeiras

---

## [0.2.1] - 2025-11-29

### 🎉 Adicionado

#### Suporte para Aplicação Web

- Middleware CORS (`cors_middleware.dart`) para permitir requisições do navegador web
- Headers CORS configurados para desenvolvimento e produção
- Suporte a requisições preflight (OPTIONS)
- Integração do middleware CORS no pipeline do servidor

### 🔧 Alterado

- Pipeline do servidor atualizado para incluir middleware CORS como primeiro middleware
- Headers HTTP agora incluem `Access-Control-Allow-*` para requisições cross-origin

### 📝 Documentação

- Documentação inline no middleware CORS explicando comportamento para apps móveis vs web

---

## [0.2.0] - 2025-01-XX

### 🎉 Adicionado

#### Sistema de Anamnese

- Migrations para tabelas `anamnesis` e `anamnesis_templates`
- Models Dart completos (`Anamnesis` e `AnamnesisTemplate`)
- Repository com CRUD completo para anamnese e templates
- Controller com lógica de negócio
- Handler com endpoints HTTP RESTful
- Routes integradas ao servidor
- Template padrão do sistema com 13 seções e ~70 campos:
  - Dados Demográficos
  - Queixa Principal
  - Histórico Médico
  - Histórico Psiquiátrico
  - Histórico Familiar
  - Histórico de Desenvolvimento
  - Vida Social
  - Vida Profissional/Acadêmica
  - Hábitos de Vida
  - Sexualidade
  - Aspectos Legais
  - Expectativas
  - Observações Gerais
- Script `seed_default_anamnesis_template.dart` para inserir template padrão
- Testes automatizados (unitários e integração)
- Suporte a templates customizáveis por terapeuta

### 🔧 Alterado

- Migrations atualizadas para remover perfis comportamentais da tabela de pacientes
- Estrutura de dados de pacientes atualizada

### 📝 Documentação

- Adicionado `ANAMNESIS_TEMPLATE_MODEL.md` com documentação completa do modelo
- Adicionado `TESTE_ANAMNESIS_API.md` com guia de testes
- Adicionado `PROXIMOS_PASSOS_ANAMNESIS.md` com roadmap

---

## [0.1.0] - 2024-11-XX

### 🎉 Adicionado

#### Autenticação e Autorização

- Sistema completo de autenticação com JWT
- Endpoints de login e logout
- Refresh tokens para renovação automática de sessão
- Blacklist de tokens para logout seguro
- Middleware de autenticação (`auth_middleware.dart`)
- Suporte a múltiplos roles (therapist, patient, admin)
- Verificação de email e telefone
- Suporte a Two-Factor Authentication (TFA) - estrutura preparada

#### Gestão de Usuários e Terapeutas

- Endpoints para cadastro de usuários
- Endpoints para cadastro completo de terapeutas
- Sistema de planos e assinaturas (Gratuito, Básico, Premium)
- Limites de pacientes por plano
- Endpoints para atualização de perfil de terapeuta
- Validação de dados profissionais (CRP, CRM, etc.)

#### Gestão de Pacientes

- CRUD completo de pacientes via API REST
- Endpoints para listagem, criação, atualização e exclusão
- Validação de dados de pacientes
- Suporte a filtros na listagem
- Row Level Security (RLS) para isolamento de dados

#### Agenda e Agendamentos

- Endpoints para criação e gerenciamento de agendamentos
- Validação de horários e prevenção de sobreposição
- Suporte a recorrência de agendamentos
- Configuração de horários de trabalho do terapeuta

#### Sessões Terapêuticas

- Endpoints para registro completo de sessões
- Armazenamento de dados clínicos da sessão
- Histórico de sessões por paciente
- Status de pagamento por sessão
- Suporte a múltiplos tipos e modalidades de sessão

#### Módulo Financeiro

- Endpoints para transações financeiras
- Controle de pagamentos por sessão
- Status de pagamento (pendente, pago, isento)
- Relatórios financeiros básicos

#### Banco de Dados

- Sistema de migrations com PostgreSQL
- Row Level Security (RLS) implementado
- Políticas de segurança para isolamento de dados
- Triggers para atualização automática de timestamps
- Constraints e validações no banco de dados

#### Infraestrutura

- Arquitetura em Dart com Shelf framework
- Sistema de rotas modularizado
- Handlers base para padronização
- Controllers com lógica de negócio
- Repositories para acesso a dados
- Configuração via variáveis de ambiente
- Logging estruturado
- Tratamento de erros centralizado
- Connection pool para PostgreSQL

#### Testes

- Testes unitários de controllers
- Testes de integração de handlers
- Testes de repositórios
- Helpers para testes

### 🔧 Alterado

- Estrutura inicial do projeto organizada
- Padrões de código estabelecidos

### 📝 Documentação

- README principal do servidor
- Documentação de APIs
- Guias de instalação e configuração

---

[0.2.0]: https://github.com/seu-usuario/terafy/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/seu-usuario/terafy/releases/tag/v0.1.0

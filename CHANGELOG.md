# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [0.2.0] - 2025-01-XX

### 🎉 Adicionado

#### Sistema de Anamnese
- **Backend Completo**
  - Migrations para tabelas `anamnesis` e `anamnesis_templates`
  - Models Dart completos (`Anamnesis` e `AnamnesisTemplate`)
  - Repository com CRUD completo para anamnese e templates
  - Controller com lógica de negócio
  - Handler com endpoints HTTP RESTful
  - Routes integradas ao servidor
  - Template padrão do sistema com 13 seções e ~70 campos
  - Scripts para inserir template padrão no banco de dados
  - Testes automatizados (unitários e integração)

- **Frontend Completo**
  - Models completos para Anamnese, Template, Seções e Campos
  - Repositories (interfaces e implementações) para anamnese e templates
  - BLoC pattern implementado para gerenciamento de estado
  - Página de visualização de anamnese (`AnamnesisViewPage`)
  - Página de formulário de anamnese (`AnamnesisFormPage`)
  - Widgets reutilizáveis para campos e seções dinâmicas
  - Integração completa com backend via HTTP
  - Suporte a templates dinâmicos e customizáveis
  - Validação de campos obrigatórios
  - Tratamento de erros e estados de loading

- **Documentação**
  - Documentação completa do modelo de template
  - Guia de testes da API de anamnese
  - README dos templates
  - Documentação dos próximos passos

#### Melhorias no Módulo de Pacientes
- Remoção de perfis comportamentais da tabela de pacientes (migração)
- Atualização do modelo de paciente para refletir mudanças
- Melhorias na estrutura de dados do paciente

### 🔧 Alterado
- Estrutura de dados de pacientes para remover referências a perfis comportamentais
- Migrations atualizadas para refletir nova estrutura

### 📝 Documentação
- Adicionado `ANAMNESIS_TEMPLATE_MODEL.md` com documentação completa do modelo
- Adicionado `TESTE_ANAMNESIS_API.md` com guia de testes
- Adicionado `PROXIMOS_PASSOS_ANAMNESIS.md` com roadmap

---

## [0.1.0] - 2024-11-XX

### 🎉 Adicionado

#### Autenticação e Autorização
- Sistema completo de autenticação com JWT
- Login e logout de usuários
- Refresh tokens para renovação automática de sessão
- Blacklist de tokens para logout seguro
- Middleware de autenticação
- Suporte a múltiplos roles (therapist, patient, admin)
- Verificação de email e telefone
- Suporte a Two-Factor Authentication (TFA) - estrutura preparada
- Persistência de sessão no frontend

#### Gestão de Usuários e Terapeutas
- Cadastro de usuários
- Cadastro completo de terapeutas com perfil profissional
- Sistema de planos e assinaturas (Gratuito, Básico, Premium)
- Limites de pacientes por plano
- Atualização de perfil de terapeuta
- Validação de dados profissionais (CRP, CRM, etc.)

#### Gestão de Pacientes
- CRUD completo de pacientes
- Cadastro em múltiplas etapas (wizard):
  - Dados pessoais básicos
  - Informações de contato
  - Dados profissionais e sociais
  - Informações de saúde
  - Dados iniciais de anamnese (versão básica)
- Listagem de pacientes com filtros
- Dashboard individual do paciente
- Status de pacientes (ativo, inativo, avaliado, em alta, alta concluída)
- Contato de emergência e responsável legal
- Informações de convênio e pagamento
- Histórico de sessões do paciente

#### Agenda e Agendamentos
- Sistema completo de agenda
- Criação de agendamentos
- Visualização de agendamentos por data
- Status de agendamentos (disponível, reservado, confirmado, realizado, cancelado)
- Prevenção de sobreposição de agendamentos
- Suporte a recorrência de agendamentos
- Configuração de horários de trabalho do terapeuta

#### Sessões Terapêuticas
- Registro completo de sessões
- Dados clínicos da sessão:
  - Humor/estado emocional do paciente
  - Temas abordados
  - Notas clínicas protegidas
  - Comportamento observado
  - Técnicas e intervenções utilizadas
  - Tarefas terapêuticas (homework)
  - Progressos observados
  - Próximos passos
  - Nível de risco (baixo, médio, alto)
- Histórico de sessões
- Detalhes completos da sessão
- Evolução do paciente ao longo das sessões
- Status de pagamento por sessão
- Tipos de sessão (presencial, online-vídeo, online-áudio, telefone, grupo)
- Modalidades (individual, casal, família, grupo)

#### Módulo Financeiro
- Transações financeiras
- Controle de pagamentos por sessão
- Status de pagamento (pendente, pago, isento)
- Relatórios financeiros básicos
- Detalhes de transações
- Histórico financeiro

#### Segurança e Conformidade
- Row Level Security (RLS) implementado no PostgreSQL
- Isolamento de dados por terapeuta
- Políticas de segurança no banco de dados
- Criptografia de senhas
- Validação de tokens JWT
- Middleware de autenticação em todas as rotas protegidas

#### Infraestrutura
- Arquitetura backend em Dart com Shelf
- Frontend Flutter multiplataforma
- Banco de dados PostgreSQL
- Sistema de migrations
- Docker e Docker Compose para desenvolvimento e produção
- Scripts de deploy
- Configuração de ambiente via variáveis de ambiente
- Logging estruturado
- Tratamento de erros centralizado

#### Testes
- Testes unitários de autenticação
- Testes de integração
- Testes de BLoC no frontend
- Testes de repositórios
- Helpers para testes

#### Documentação
- Documentação de modelos de dados
- Documentação de APIs
- Guias de instalação e configuração
- Documentação de negócio completa
- Plano de testes

### 🔧 Alterado
- Estrutura inicial do projeto organizada
- Padrões de código estabelecidos

### 📝 Documentação
- README principal do projeto
- Documentação de entidades de negócio
- Guias de uso e configuração

---

[0.2.0]: https://github.com/seu-usuario/terafy/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/seu-usuario/terafy/releases/tag/v0.1.0


# Plano de Testes Manuais - Frontend Terafy

## Pré-requisitos

- Backend rodando em `http://localhost:8080`
- Banco de dados com migrations executadas
- Usuário de teste criado (ou criar durante os testes)

---

## 1. Autenticação e Cadastro

### 1.1 Login

- [x] Login com credenciais válidas ✅ (Teste automatizado: `login_bloc_test.dart`)
- [x] Login com credenciais inválidas (erro) ✅ (Teste automatizado: `login_bloc_test.dart`)
- [x] Validação de campos obrigatórios ✅ (Teste de integração: `login_visual_test.dart`)
- [x] Redirecionamento após login bem-sucedido ✅ (Teste de integração: `login_visual_test.dart`)
- [x] Persistência de sessão (fechar e reabrir app) ✅ (Teste automatizado: `login_bloc_test.dart`)

### 1.2 Cadastro de Terapeuta

- [] Cadastro simples (email/senha)
- [] Cadastro completo (dados pessoais, profissional, plano)
- [] Validação de campos obrigatórios
- [] Seleção de plano
- [] Redirecionamento após cadastro

### 1.3 Logout

- [x] Logout funcional ✅ (Teste automatizado: `login_bloc_test.dart`)
- [x] Limpeza de tokens ✅ (Teste automatizado: `login_bloc_test.dart`)
- [ ] Redirecionamento para tela de login (teste de integração necessário)

---

## 2. Home/Dashboard

### 2.1 Carregamento Inicial

- [ ] Exibição de estatísticas do dia (sessões pendentes/confirmadas)
- [ ] Exibição de estatísticas mensais (taxa de conclusão, total de sessões)
- [ ] Lista de agendamentos do dia
- [ ] Cards de ações rápidas

### 2.2 Navegação

- [ ] Navegação entre abas (Home, Agenda, Pacientes, Sessões, Financeiro)
- [ ] Navegação para detalhes de agendamento

---

## 3. Pacientes

### 3.1 Cadastro de Paciente

- [ ] Cadastro completo (todos os passos do wizard)
- [ ] Validação de campos obrigatórios
- [ ] Upload de foto (se implementado)
- [ ] Seleção de status inicial
- [ ] Confirmação e salvamento

### 3.2 Listagem de Pacientes

- [ ] Exibição da lista de pacientes
- [ ] Filtros por status (ativo, avaliado, inativo, etc.)
- [ ] Busca por nome/email/telefone
- [ ] Navegação para detalhes do paciente

### 3.3 Dashboard do Paciente

- [ ] Visualização de informações do paciente
- [ ] Exibição de total de sessões concluídas
- [ ] Exibição de data/hora da última sessão
- [ ] Histórico de sessões
- [ ] Navegação para criar nova sessão

### 3.4 Edição de Paciente

- [ ] Edição de dados pessoais
- [ ] Alteração de status
- [ ] Atualização de informações de contato

---

## 4. Agenda/Agendamentos

### 4.1 Visualização da Agenda

- [ ] Exibição da semana (todos os dias úteis)
- [ ] Toggle para sábado e domingo
- [ ] Navegação entre semanas (3 dias por vez)
- [ ] Cards de agendamentos com horários corretos
- [ ] Diferenciação visual entre tipos (sessão, bloqueio, pessoal)

### 4.2 Criação de Agendamento

- [ ] Agendamento único (sessão)
- [ ] Agendamento único (bloqueio/pessoal)
- [ ] Seleção de paciente (para sessões)
- [ ] Seleção de data e hora (dropdown de 30 em 30 min)
- [ ] Seleção de duração (30, 60, 90, 120 min para sessões)
- [ ] Recorrência diária (com dias da semana e semanas)
- [ ] Recorrência semanal (com número de semanas)
- [ ] Auto-relacionamento de agendamentos recorrentes
- [ ] Campos opcionais (sala, link online, notas)

### 4.3 Detalhes do Agendamento

- [ ] Visualização de informações completas
- [ ] Informações do paciente (nome, sessões concluídas, última sessão)
- [ ] Status do agendamento
- [ ] Botão para navegar à sessão vinculada (se existir)

### 4.4 Fluxo de Status do Agendamento

- [ ] Confirmar agendamento (reserved → confirmed)
- [ ] Criação automática de sessão ao confirmar
- [ ] Cancelar agendamento (com motivo)
- [ ] Cancelamento de sessão vinculada ao cancelar agendamento
- [ ] Visualização de feedback (snackbars)

### 4.5 Edição de Agendamento

- [ ] Edição de data/hora
- [ ] Edição de duração
- [ ] Edição de notas
- [ ] Atualização de informações

---

## 5. Sessões

### 5.1 Criação de Sessão

- [ ] Criação manual de sessão
- [ ] Seleção de paciente
- [ ] Número de sessão automático
- [ ] Preenchimento de dados da sessão
- [ ] Valores e status de pagamento

### 5.2 Listagem de Sessões

- [ ] Lista de sessões do paciente
- [ ] Filtros por status
- [ ] Ordenação por data
- [ ] Navegação para detalhes

### 5.3 Detalhes da Sessão

- [ ] Visualização de informações completas
- [ ] Link para agendamento vinculado (se existir)
- [ ] Botão para editar evolução

### 5.4 Evolução da Sessão

- [ ] Edição de notas clínicas
- [ ] Preenchimento de campos de evolução
- [ ] Salvamento de alterações

### 5.5 Fluxo de Status da Sessão

- [ ] Confirmar sessão
- [ ] Marcar como em andamento
- [ ] Completar sessão (completed)
- [ ] Atualização automática do agendamento vinculado para completed
- [ ] Cancelar sessão (com motivo)
- [ ] Marcar como falta (noShow)

### 5.6 Integração Financeira

- [ ] Criação automática de transação ao completar sessão (se tiver charged_amount)
- [ ] Verificação de transação criada no módulo financeiro

---

## 6. Financeiro

### 6.1 Resumo Financeiro

- [ ] Exibição de totais (recebido, pendente, atrasado)
- [ ] Estatísticas de sessões (completas, pendentes)
- [ ] Filtro por período (mês atual, mês anterior, customizado)

### 6.2 Listagem de Transações

- [ ] Lista de transações
- [ ] Filtros por status (pendente, pago, atrasado, cancelado)
- [ ] Filtros por paciente
- [ ] Filtros por período
- [ ] Ordenação por data de vencimento

### 6.3 Detalhes da Transação

- [ ] Visualização de informações completas
- [ ] Link para sessão vinculada (se existir)
- [ ] Informações de pagamento

### 6.4 Operações Financeiras

- [ ] Criar transação manual
- [ ] Marcar transação como paga
- [ ] Atualização automática de payment_status da sessão vinculada
- [ ] Cancelar transação
- [ ] Editar transação

### 6.5 Relatórios

- [ ] Gráfico de receita por período
- [ ] Gráfico de status de pagamentos
- [ ] Comparativo mensal
- [ ] Filtros de período nos relatórios

---

## 7. Integrações e Fluxos Cruzados

### 7.1 Fluxo Completo: Agendamento → Sessão → Financeiro

- [ ] Criar agendamento de sessão
- [ ] Confirmar agendamento (cria sessão automaticamente)
- [ ] Navegar para sessão criada
- [ ] Completar sessão (atualiza agendamento para completed)
- [ ] Verificar transação financeira criada automaticamente
- [ ] Marcar transação como paga
- [ ] Verificar atualização de payment_status da sessão

### 7.2 Fluxo de Cancelamento

- [ ] Cancelar agendamento com sessão vinculada
- [ ] Verificar cancelamento automático da sessão
- [ ] Cancelar sessão com agendamento vinculado
- [ ] Verificar impacto no agendamento

### 7.3 Sincronização de Dados

- [ ] Atualização de total_sessions do paciente (via trigger)
- [ ] Atualização de last_session_date do paciente
- [ ] Geração automática de session_number
- [ ] Auto-relacionamento de agendamentos recorrentes

---

## 8. Validações e Tratamento de Erros

### 8.1 Validações de Formulários

- [ ] Campos obrigatórios
- [ ] Formato de email
- [ ] Formato de telefone
- [ ] Datas válidas
- [ ] Valores numéricos

### 8.2 Tratamento de Erros

- [ ] Erro de conexão com backend
- [ ] Erro 404 (recurso não encontrado)
- [ ] Erro 400 (validação)
- [ ] Erro 401 (não autorizado)
- [ ] Erro 500 (servidor)
- [ ] Mensagens de erro amigáveis
- [ ] Feedback visual (loading, snackbars)

### 8.3 Estados de Loading

- [ ] Loading durante requisições
- [ ] Desabilitação de botões durante operações
- [ ] Feedback visual de sucesso/erro

---

## 9. Navegação e UX

### 9.1 Navegação Geral

- [ ] Navegação entre telas principais
- [ ] Botão voltar funcionando
- [ ] Deep linking (se implementado)
- [ ] Persistência de estado ao navegar

### 9.2 Responsividade

- [ ] Layout em diferentes tamanhos de tela
- [ ] Orientação portrait/landscape (se aplicável)
- [ ] Scroll em listas longas

### 9.3 Acessibilidade

- [ ] Contraste de cores
- [ ] Tamanho de fontes legível
- [ ] Áreas de toque adequadas

---

## 10. Casos Especiais

### 10.1 Dados Vazios

- [ ] Lista vazia de pacientes
- [ ] Lista vazia de agendamentos
- [ ] Lista vazia de sessões
- [ ] Lista vazia de transações
- [ ] Mensagens apropriadas para estados vazios

### 10.2 Dados com Relacionamentos

- [ ] Paciente sem sessões
- [ ] Agendamento sem sessão vinculada
- [ ] Sessão sem agendamento vinculado
- [ ] Transação sem sessão vinculada

### 10.3 Status e Estados

- [ ] Todos os status de agendamento (reserved, confirmed, completed, cancelled)
- [ ] Todos os status de sessão
- [ ] Todos os status de transação
- [ ] Todos os status de paciente (active, evaluated, inactive, etc.)

---

## Checklist Final

- [ ] Todos os módulos principais testados
- [ ] Fluxos críticos validados
- [ ] Integrações funcionando
- [ ] Tratamento de erros adequado
- [ ] UX consistente
- [ ] Performance aceitável
- [ ] Sem crashes ou erros críticos
# Sistema de Gerenciamento Clínico para Terapeutas
## Documentação de Entidades de Negócio

---

## 1. ENTIDADES PRINCIPAIS

### 1.1 Usuário/Terapeuta
Representa o profissional que utiliza o sistema.

**Atributos:**
- ID único
- Nome completo
- CPF
- Email
- Telefone/WhatsApp
- Data de nascimento
- Foto de perfil
- Registro profissional (CRP, CRM, etc.)
- Número do registro
- Especialidades/abordagens terapêuticas (array)
- Formação acadêmica
- Apresentação profissional
- Endereço do consultório
- Plano de assinatura (Gratuito, Básico, Premium)
- Data de início do plano
- Limite de pacientes (conforme plano)
- Configurações de agenda
- Preferências de notificação
- Dados bancários para recebimento
- Status da conta (ativo, suspenso, cancelado)
- Data de criação
- Última atualização

**Relacionamentos:**
- Possui múltiplos Pacientes
- Possui múltiplas Sessões
- Possui configurações de Agenda
- Possui transações Financeiras

---

### 1.2 Paciente/Cliente
Representa a pessoa atendida pelo terapeuta.

**Atributos:**
- ID único
- ID do terapeuta responsável
- Nome completo
- Data de nascimento
- Idade
- CPF (opcional)
- RG
- Gênero
- Estado civil
- Endereço completor
- Email
- Telefone(s)
- Profissão
- Escolaridade
- Contato de emergência (nome, relação, telefone)
- Responsável legal (se menor - nome, CPF, telefone)
- Convênio/plano de saúde
- Número da carteirinha
- Forma de pagamento preferencial
- Valor da sessão
- Termo de consentimento (data de aceite)
- Aceite LGPD (data)
- Status (ativo, inativo, em alta, alta concluída)
- Motivo da inativação
- Data de início do tratamento
- Data da última sessão
- Total de sessões realizadas
- Perfil comportamental (ID referência)
- Tags personalizadas (array)
- Observações gerais
- Foto (opcional)
- Cor de identificação (para agenda)
- Data de criação
- Última atualização

**Relacionamentos:**
- Pertence a um Terapeuta
- Possui uma Anamnese
- Possui múltiplas Sessões
- Possui um ou mais Perfis Comportamentais
- Possui um Prontuário/Evolução
- Possui Plano Terapêutico
- Possui Avaliações/Testes
- Possui Documentos
- Possui registros Financeiros

---

### 1.3 Anamnese
Primeira avaliação completa do paciente.

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta
- Data de realização
- Data de atualização

**Dados Demográficos:**
- Naturalidade
- Nacionalidade
- Religião/espiritualidade
- Com quem reside
- Composição familiar

**Queixa Principal:**
- Descrição da queixa
- Quando começou
- Frequência
- Intensidade (escala 0-10)
- Fatores desencadeantes
- O que já tentou fazer

**Histórico Médico:**
- Doenças atuais
- Doenças prévias
- Cirurgias realizadas
- Alergias
- Internações
- Acompanhamento médico atual

**Histórico Psiquiátrico:**
- Diagnósticos prévios
- Tratamentos anteriores
- Internações psiquiátricas
- Medicações psiquiátricas atuais (nome, dose, horário)
- Médico psiquiatra (nome, contato)
- Tentativas de suicídio (histórico)
- Automutilação
- Uso de substâncias (álcool, drogas)

**Histórico Familiar:**
- Doenças mentais na família
- Histórico de suicídio
- Relacionamento com pais
- Relacionamento com irmãos
- Dinâmica familiar

**Histórico de Desenvolvimento:**
- Gravidez e parto
- Desenvolvimento motor
- Desenvolvimento da linguagem
- Marcos do desenvolvimento
- Escolarização

**Vida Social:**
- Círculo social
- Qualidade das amizades
- Relacionamentos amorosos
- Rede de apoio
- Atividades de lazer
- Hobbies

**Vida Profissional/Acadêmica:**
- Ocupação atual
- Satisfação profissional
- Conflitos no trabalho
- Histórico profissional
- Situação acadêmica (se estudante)

**Hábitos de Vida:**
- Padrão de sono (horas, qualidade)
- Alimentação
- Atividade física
- Uso de tecnologia/internet
- Rotina diária

**Sexualidade:**
- Orientação sexual
- Vida sexual ativa
- Satisfação sexual
- Questões relacionadas

**Aspectos Legais:**
- Processos judiciais em andamento
- Histórico criminal
- Questões de guarda/família

**Expectativas:**
- O que espera do tratamento
- Objetivos pessoais
- Disponibilidade para sessões
- Comprometimento

**Observações Gerais:**
- Impressões do terapeuta
- Aspectos relevantes não categorizados
- Campos personalizáveis por abordagem

**Relacionamentos:**
- Pertence a um Paciente
- Criada por um Terapeuta
- Pode ter anexos (Documentos)

---

### 1.4 Sessão/Atendimento
Representa cada encontro terapêutico.

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta
- Data e horário de início
- Data e horário de término
- Duração (minutos)
- Número da sessão (sequencial)
- Tipo de atendimento (presencial, online-vídeo, online-áudio, telefone, grupo)
- Modalidade (individual, casal, família, grupo)
- Local (se presencial)
- Link da sala (se online)
- Status (agendada, confirmada, em andamento, realizada, cancelada-terapeuta, cancelada-paciente, falta)
- Motivo do cancelamento
- Horário do cancelamento
- Valor cobrado
- Status do pagamento (pendente, pago, isento)

**Registro Clínico:**
- Humor/estado emocional do paciente (escala ou descritivo)
- Temas abordados (array de tags)
- Conteúdo da sessão (notas protegidas)
- Comportamento observado
- Técnicas/intervenções utilizadas (array)
- Recursos utilizados (exercícios, materiais)
- Tarefas/orientações dadas
- Reações do paciente
- Progressos observados
- Dificuldades identificadas
- Próximos passos
- Objetivos para próxima sessão
- Necessidade de encaminhamento
- Risco atual (baixo, médio, alto)
- Observações importantes

**Dados Administrativos:**
- Confirmação de presença (data/hora)
- Lembrete enviado (sim/não, quando)
- Avaliação da sessão pelo paciente (opcional)
- Anexos (áudios, imagens, documentos)
- Data de criação do registro
- Última modificação

**Relacionamentos:**
- Pertence a um Paciente
- Conduzida por um Terapeuta
- Relacionada ao Prontuário
- Pode ter Documentos associados
- Gera registro Financeiro

---

### 1.5 Evolução/Prontuário
Consolidação do histórico clínico e evolução do paciente.

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta

**Avaliação Clínica:**
- Hipóteses diagnósticas (array, com datas)
- CID-10 (se aplicável)
- Comorbidades
- Fatores de risco identificados
- Fatores protetivos
- Recursos pessoais do paciente
- Pontos fortes

**Plano de Tratamento:**
- Abordagem terapêutica utilizada
- Frequência recomendada
- Duração estimada
- Técnicas principais
- Estratégias de intervenção

**Evolução Geral:**
- Resumo do progresso
- Mudanças observadas
- Ganhos terapêuticos
- Dificuldades persistentes
- Alterações no quadro clínico

**Intercorrências:**
- Crises
- Situações de emergência
- Alterações medicamentosas
- Internações
- Mudanças significativas

**Encaminhamentos:**
- Profissionais contactados
- Relatórios enviados
- Pareceres recebidos

**Reavaliações:**
- Datas de reavaliação
- Ajustes no plano terapêutico
- Mudanças de objetivos

**Alta:**
- Data da alta
- Tipo de alta (terapêutica, abandono, encaminhamento)
- Motivo
- Condições da alta
- Recomendações

**Auditoria:**
- Histórico completo de alterações
- Data/hora de cada modificação
- Usuário que modificou
- Campo modificado
- Valor anterior

**Relacionamentos:**
- Pertence a um Paciente
- Mantido por um Terapeuta
- Relacionado a todas as Sessões
- Pode ter múltiplos Documentos

---

### 1.6 Perfil Comportamental
Sistema de classificação e mapeamento comportamental do paciente.

**Atributos:**
- ID único
- ID do paciente
- Data da avaliação
- Tipo de sistema utilizado (DISC, Big Five, Eneagrama, personalizado, etc.)

**Classificação:**
- Perfil predominante
- Perfis secundários
- Percentuais/pontuações por dimensão
- Gráfico/visualização

**Características Identificadas:**
- Traços predominantes (array)
- Padrões de comportamento
- Estilos de comunicação preferidos
- Forma de lidar com conflitos
- Motivações principais
- Valores centrais
- Medos e inseguranças

**Aspectos Clínicos:**
- Gatilhos emocionais (array)
- Situações desafiadoras
- Padrões disfuncionais
- Mecanismos de defesa
- Estratégias de enfrentamento
- Crenças centrais
- Esquemas cognitivos

**Estratégias Terapêuticas:**
- Abordagens que funcionam melhor
- Técnicas mais efetivas
- Tipo de linguagem a utilizar
- Ritmo ideal de trabalho
- Formato de sessão preferencial

**Relacionamentos:**
- Forma de se relacionar
- Estilo de apego
- Padrões relacionais
- Dificuldades interpessoais

**Evolução:**
- Mudanças observadas ao longo do tempo
- Reavaliações periódicas
- Comparativos entre avaliações
- Gráficos de evolução

**Observações:**
- Notas do terapeuta
- Validação com paciente
- Insights importantes

**Relacionamentos:**
- Pertence a um Paciente
- Avaliado por um Terapeuta
- Pode ter múltiplas versões (histórico)

---

### 1.7 Agenda/Agendamento
Gestão de horários e compromissos.

**Atributos do Terapeuta:**
- ID único do terapeuta
- Horários de trabalho por dia da semana
- Intervalo entre sessões
- Duração padrão da sessão
- Locais de atendimento
- Dias de folga
- Feriados bloqueados
- Bloqueios personalizados (viagens, eventos)

**Atributos do Agendamento:**
- ID único
- ID do terapeuta
- ID do paciente (se aplicável)
- Data e horário
- Duração
- Tipo (sessão, compromisso pessoal, bloqueio)
- Recorrência (única, semanal, quinzenal, mensal)
- Data final da recorrência
- Exceções na recorrência
- Status (disponível, reservado, confirmado, realizado, cancelado)
- Cor de identificação
- Lembretes (array de configurações)
- Lembrete enviado (data/hora)
- Confirmação do paciente (data/hora)
- Notas do agendamento
- Sala/local
- Link online (se aplicável)

**Configurações de Lembretes:**
- Enviar lembrete (sim/não)
- Tempo de antecedência (24h, 48h, 1 semana)
- Canal (email, SMS, WhatsApp, notificação push)
- Mensagem personalizada

**Sala de Espera Virtual:**
- Paciente em espera (sim/não)
- Horário de chegada
- Status (aguardando, em atendimento)

**Gestão de Faltas:**
- Política de cancelamento
- Prazo mínimo para cancelamento
- Cobrança de faltas
- Reposições permitidas
- Controle de faltas por paciente

**Relacionamentos:**
- Pertence a um Terapeuta
- Pode estar vinculado a um Paciente
- Gera uma Sessão (quando realizado)

---

### 1.8 Documentos
Geração e armazenamento de documentos clínicos.

**Tipos de Documentos:**
- Atestado
- Declaração de comparecimento
- Relatório psicológico
- Parecer
- Laudo
- Encaminhamento
- Prescrição/orientação
- Contrato terapêutico
- Termo de consentimento
- Autorização de imagem

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta
- Tipo de documento
- Título
- Data de emissão
- Conteúdo (texto formatado)
- Template utilizado
- Assinatura digital
- Hash de verificação
- Status (rascunho, emitido, enviado)
- Data de envio
- Visualizado pelo paciente (data/hora)
- Validade (se aplicável)
- CID (se aplicável)
- Observações
- Arquivo gerado (PDF)
- Data de criação
- Última modificação

**Templates:**
- Nome do template
- Tipo de documento
- Conteúdo base
- Campos variáveis
- Formatação
- Cabeçalho/rodapé

**Relacionamentos:**
- Pertence a um Paciente
- Emitido por um Terapeuta
- Pode estar vinculado a uma Sessão
- Parte do Prontuário

---

### 1.9 Financeiro
Controle de pagamentos e faturamento.

**Atributos de Configuração:**
- ID do terapeuta
- Valores padrão por modalidade
- Formas de pagamento aceitas
- Dados bancários
- Configurações de nota fiscal
- Política de cobrança
- Política de reembolso

**Transação:**
- ID único
- ID do paciente
- ID do terapeuta
- ID da sessão (se aplicável)
- Data da transação
- Tipo (recebimento, estorno, desconto)
- Valor
- Forma de pagamento (dinheiro, PIX, cartão débito, cartão crédito, transferência, boleto, convênio)
- Status (pendente, pago, atrasado, cancelado)
- Data de vencimento
- Data de pagamento
- Comprovante (anexo)
- Observações
- Categoria (sessão, avaliação, documento, outro)
- Número da nota fiscal
- Emitiu NF (sim/não)

**Pacote/Plano de Pagamento:**
- ID único
- ID do paciente
- Descrição (ex: "Pacote 4 sessões")
- Valor total
- Desconto aplicado
- Número de sessões inclusas
- Sessões utilizadas
- Sessões restantes
- Data de compra
- Validade
- Status (ativo, expirado, cancelado)

**Inadimplência:**
- ID do paciente
- Valor total em aberto
- Quantidade de sessões não pagas
- Data da primeira pendência
- Tentativas de cobrança
- Status do paciente (regular, em atraso, bloqueado)

**Relatórios Financeiros:**
- Período
- Receita total
- Receita por forma de pagamento
- Receita por tipo de atendimento
- Taxa de inadimplência
- Ticket médio
- Projeções

**Relacionamentos:**
- Vinculado a um Terapeuta
- Vinculado a um Paciente
- Relacionado a Sessões
- Pode ter Comprovantes (Documentos)

---

### 1.10 Plano Terapêutico
Planejamento estruturado do tratamento.

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta
- Data de criação
- Data de revisão
- Status (ativo, em revisão, concluído)

**Objetivos:**
- ID do objetivo
- Descrição
- Prazo (curto/médio/longo prazo)
- Data prevista
- Prioridade (alta, média, baixa)
- Status (não iniciado, em progresso, concluído, abandonado)
- Indicadores de progresso
- Métrica de sucesso

**Metas Mensuráveis:**
- Descrição específica
- Como será medida
- Frequência de avaliação
- Resultado esperado
- Resultado atual

**Intervenções Planejadas:**
- Técnica/abordagem
- Frequência de aplicação
- Materiais necessários
- Duração estimada
- Objetivo relacionado

**Frequência Recomendada:**
- Sessões por semana/mês
- Duração de cada sessão
- Duração total estimada do tratamento
- Reavaliações programadas

**Estratégias:**
- Estratégias principais
- Técnicas específicas
- Recursos a utilizar
- Tarefas terapêuticas
- Homework

**Monitoramento:**
- Indicadores a acompanhar
- Instrumentos de avaliação
- Frequência de medição
- Registros do paciente

**Reavaliações:**
- Data da reavaliação
- Objetivos alcançados
- Objetivos em progresso
- Ajustes necessários
- Novos objetivos
- Observações

**Observações:**
- Fatores que podem influenciar
- Potenciais obstáculos
- Recursos disponíveis
- Rede de apoio

**Relacionamentos:**
- Pertence a um Paciente
- Criado por um Terapeuta
- Relacionado ao Prontuário
- Vinculado a Objetivos específicos

---

## 2. ENTIDADES COMPLEMENTARES

### 2.1 Avaliações/Testes
Instrumentos de avaliação psicológica.

**Tipos Comuns:**
- Inventários (Beck, Hamilton, etc.)
- Escalas (ansiedade, depressão, estresse)
- Questionários
- Testes projetivos
- Testes neuropsicológicos
- Avaliações personalizadas

**Atributos:**
- ID único
- ID do paciente
- ID do terapeuta
- Nome do instrumento
- Tipo
- Data de aplicação
- Finalidade
- Respostas/protocolo
- Pontuação bruta
- Pontuação ponderada
- Interpretação
- Percentil
- Classificação
- Gráfico de resultados
- Observações do aplicador
- Arquivo digitalizado (se aplicável)

**Histórico:**
- Aplicações anteriores
- Comparação entre aplicações
- Gráfico de evolução
- Mudanças significativas

**Relacionamentos:**
- Pertence a um Paciente
- Aplicado por um Terapeuta
- Parte do Prontuário
- Pode gerar Documentos (laudos)

---

### 2.2 Recursos Terapêuticos
Biblioteca de materiais de apoio.

**Atributos:**
- ID único
- ID do terapeuta (se privado) ou público
- Título
- Descrição
- Tipo (exercício, áudio, vídeo, texto, PDF, imagem, link)
- Categoria (relaxamento, psicoeducação, TCC, mindfulness, etc.)
- Tags
- Arquivo/conteúdo
- Link externo
- Duração (se aplicável)
- Nível de dificuldade
- Público-alvo
- Instruções de uso
- Data de criação
- Número de usos
- Avaliação

**Compartilhamento:**
- Compartilhado com pacientes (array de IDs)
- Data do compartilhamento
- Visualizado (sim/não, data)
- Feedback do paciente

**Organização:**
- Pastas/categorias
- Favoritos
- Mais utilizados
- Recomendados

**Relacionamentos:**
- Criado por um Terapeuta
- Pode ser compartilhado com Pacientes
- Usado em Sessões
- Parte do Plano Terapêutico

---

### 2.3 Supervisão
Para acompanhamento profissional e casos complexos.

**Atributos:**
- ID único
- ID do terapeuta supervisionado
- ID do supervisor (se cadastrado no sistema)
- Nome do supervisor
- CRP do supervisor
- Abordagem do supervisor
- Data da supervisão
- Duração
- Modalidade (individual, grupo)
- Tipo (presencial, online)

**Conteúdo:**
- Casos discutidos (array de IDs de pacientes - anonimizados se necessário)
- Questões levantadas
- Dificuldades apresentadas
- Orientações recebidas
- Estratégias sugeridas
- Material estudado
- Recomendações de leitura
- Próximos passos

**Controle:**
- Valor da supervisão
- Status de pagamento
- Próxima supervisão agendada
- Frequência
- Horas de supervisão acumuladas

**Relacionamentos:**
- Vinculada a um Terapeuta
- Pode referenciar Pacientes (anonimizados)
- Registro profissional

---

### 2.4 Mensagens/Comunicação
Sistema de comunicação segura.

**Atributos:**
- ID único
- ID do remetente (terapeuta ou paciente)
- ID do destinatário
- Data/hora de envio
- Assunto
- Mensagem
- Tipo (texto, áudio, arquivo)
- Anexo
- Status (enviada, entregue, lida)
- Data/hora de leitura
- Prioridade
- Relacionada a (sessão, documento, etc.)

**Configurações:**
- Notificações ativadas
- Horário de disponibilidade para mensagens
- Resposta automática
- Tempo esperado de resposta
- Avisos ao paciente sobre uso

**Categorias:**
- Mensagem clínica (relacionada ao tratamento)
- Mensagem administrativa (agendamento, pagamento)
- Emergência
- Compartilhamento de material

**Avisos Automatizados:**
- Lembrete de sessão
- Confirmação de agendamento
- Pagamento pendente
- Material compartilhado
- Documento disponível
- Tarefa atribuída

**Privacidade:**
- Criptografia end-to-end
- Autodestruição de mensagens (opcional)
- Backup seguro
- Logs de acesso

**Relacionamentos:**
- Entre Terapeuta e Paciente
- Pode ter Anexos (arquivos)
- Pode referenciar Sessões ou Documentos

---

### 2.5 Configurações do Sistema
Personalizações e preferências.

**Configurações do Terapeuta:**
- Tema (claro, escuro, personalizado)
- Idioma
- Fuso horário
- Formato de data/hora
- Moeda
- Logo/marca personalizada
- Cores do tema
- Assinatura padrão para documentos
- Rodapé de documentos

**Templates:**
- Templates de anamnese por abordagem
- Templates de evolução
- Templates de documentos
- Perguntas padrão
- Textos padrão

**Preferências Clínicas:**
- Campos obrigatórios em sessões
- Campos customizados
- Categorias personalizadas
- Tags personalizadas
- Escalas de avaliação preferidas
- Sistema de perfil comportamental

**Notificações:**
- Email
- SMS
- Push
- WhatsApp
- Horários de envio
- Frequência

**Integrações:**
- Google Calendar
- Zoom/Meet
- Gateway de pagamento
- Emissor de nota fiscal
- Backup em nuvem

**Segurança:**
- Autenticação de dois fatores
- Tempo de sessão
- IPs permitidos
- Dispositivos autorizados

**Termos e Políticas:**
- Termo de uso
- Política de privacidade
- Termo de consentimento padrão
- Contrato terapêutico padrão
- Política de cancelamento

**Relacionamentos:**
- Pertence a um Terapeuta
- Afeta todos os aspectos do sistema

---

## 3. RECURSOS ESPECIAIS

### 3.1 Dashboard Analítico
Visão consolidada da prática clínica.

**Indicadores Principais:**
- Total de pacientes ativos
- Total de sessões no período
- Taxa de comparecimento (%)
- Taxa de cancelamento (%)
- Taxa de faltas (%)
- Receita do período
- Ticket médio
- Pacientes novos no período
- Altas no período
- Pacientes em risco (faltas frequentes)

**Análises:**
- Receita por dia/semana/mês
- Sessões por dia da semana
- Horários mais ocupados
- Distribuição por tipo de atendimento
- Distribuição por perfil comportamental
- Distribuição por queixa principal
- Taxa de ocupação da agenda
- Tempo médio de tratamento
- Retenção de pacientes

**Visualizações:**
- Gráficos de linha (evolução temporal)
- Gráficos de barra (comparações)
- Gráficos de pizza (distribuições)
- Heatmaps (agenda)
- Funil de conversão
- Indicadores coloridos

**Comparativos:**
- Mês atual vs mês anterior
- Ano atual vs ano anterior
- Metas vs realizado
- Projeções

---

### 3.2 Segmentação de Carteira
Análise inteligente da base de pacientes.

**Filtros Disponíveis:**
- Perfil comportamental
- Faixa etária
- Gênero
- Queixa principal
- Status do tratamento
- Tempo de tratamento
- Frequência de sessões
- Risco de evasão
- Inadimplência
- Última sessão (recência)
- Progresso terapêutico

**Segmentos Automáticos:**
- Pacientes engajados
- Pacientes em risco de abandono
- Pacientes com alta prevista
- Pacientes inadimplentes
- Pacientes novos (< 3 meses)
- Pacientes de longo prazo (> 1 ano)
- Pacientes com perfil similar

**Ações por Segmento:**
- Envio de mensagens em massa
- Agendamento de reavaliações
- Aplicação de avaliações
- Ofertas de grupos terapêuticos
- Campanhas específicas

**Insights:**
- Padrões de comportamento por segmento
- Técnicas mais efetivas por perfil
- Tempo médio de tratamento por queixa
- Taxa de sucesso por abordagem

---

### 3.3 Compliance e Segurança
Proteção de dados e conformidade legal.

**Segurança de Dados:**
- Criptografia AES-256 em repouso
- TLS/SSL em trânsito
- Criptografia end-to-end (mensagens)
- Tokenização de dados sensíveis
- Backup automático diário
- Backup criptografado
- Disaster recovery

**Controle de Acesso:**
- Autenticação multifator
- Senha forte obrigatória
- Timeout de sessão
- Controle de dispositivos
- Histórico de login
- Alertas de acesso suspeito

**Auditoria:**
- Log de todos os acessos
- Log de todas as modificações
- Registro de exclusões
- Registro de compartilhamentos
- Registro de exportações
- Relatórios de auditoria
- Rastreabilidade completa

**LGPD:**
- Consentimento explícito
- Finalidade específica
- Direito ao esquecimento
- Portabilidade de dados
- Anonimização
- DPO (Data Protection Officer)
- Relatório de conformidade
- Canal de solicitações

**CFP (Conselho Federal de Psicologia):**
- Armazenamento seguro de prontuários
- Tempo mínimo de retenção (5 anos)
- Sigilo profissional
- Confidencialidade
- Quebra de sigilo documentada
- Termo de consentimento
- Resolução CFP 11/2018

**Backup e Recuperação:**
- Backup automático
- Múltiplas cópias
- Armazenamento geograficamente distribuído
- Teste de recuperação
- RPO (Recovery Point Objective)
- RTO (Recovery Time Objective)

---

## 4. MODELO DE PLANOS

### Plano Gratuito (até X pacientes)
**Recursos Incluídos:**
- Cadastro de até X pacientes
- Anamnese básica (template padrão)
- Registro de sessões
- Notas clínicas simples
- Agenda básica
- Perfil comportamental simplificado
- Relatórios básicos
- Armazenamento limitado

**Limitações:**
- Sem personalização de templates
- Sem documentos profissionais
- Sem controle financeiro avançado
- Sem analytics
- Sem backup automático
- Suporte por email

---

### Plano Básico
**Recursos Incluídos:**
- Pacientes ilimitados
- Anamnese completa customizável
- Registro detalhado de sessões
- Prontuário/evolução completo
- Perfil comportamental completo
- Agenda avançada com recorrência
- Lembretes automáticos (email/SMS)
- Documentos profissionais (atestados, declarações, relatórios)
- Templates personalizáveis
- Controle financeiro completo
- Gestão de pagamentos
- Relatórios financeiros
- Controle de inadimplência
- Plano terapêutico estruturado
- Biblioteca básica de recursos
- Mensagens com pacientes
- Anexos e arquivos
- Backup automático semanal
- Armazenamento de 10GB
- Suporte prioritário por email
- Relatórios básicos de desempenho

**Valor Sugerido:** R$ 59,90/mês ou R$ 599,00/ano (2 meses grátis)

---

### Plano Premium
**Recursos Incluídos:**
- **Tudo do Plano Básico +**
- Avaliações e testes psicológicos
- Biblioteca completa de instrumentos
- Histórico de avaliações com gráficos
- Analytics avançado e dashboards
- Segmentação inteligente de carteira
- Insights e recomendações
- Biblioteca expandida de recursos terapêuticos
- Upload ilimitado de materiais
- Categorização avançada
- Agendamento online para pacientes
- Portal do paciente (acesso limitado)
- Confirmação automática de sessões
- Sala de espera virtual
- Integração com Google Calendar
- Integração com Zoom/Google Meet
- Múltiplos terapeutas/equipe (até 5)
- Gestão de supervisão
- Campos e categorias customizados ilimitados
- Temas e branding personalizado
- Logo e cores personalizadas
- Documentos com marca própria
- Assinatura digital avançada
- Templates ilimitados
- Automações personalizadas
- Webhooks e API access
- Exportação avançada de dados
- Relatórios personalizados
- White label (opcional)
- Backup automático diário
- Armazenamento ilimitado
- Suporte prioritário (email + chat)
- Gerente de conta dedicado
- Treinamento personalizado

**Valor Sugerido:** R$ 149,90/mês ou R$ 1.499,00/ano (2 meses grátis)

---

### Plano Enterprise (Clínicas)
**Recursos Incluídos:**
- **Tudo do Plano Premium +**
- Terapeutas ilimitados
- Gestão multi-profissional
- Controle de permissões avançado
- Salas/consultórios múltiplos
- Gestão de agenda por sala
- Relatórios consolidados da clínica
- Dashboard gerencial
- Indicadores de produtividade por terapeuta
- Controle financeiro centralizado
- Rateio de despesas
- Gestão de convênios
- Faturamento em lote
- Integração com ERP
- Portal do paciente completo
- Agendamento online avançado
- Triagem automatizada
- Distribuição de pacientes
- Fila de espera
- Gestão de prontuários compartilhados
- Auditoria clínica
- Compliance avançado
- Customização total
- SLA garantido
- Infraestrutura dedicada
- Backup contínuo
- Suporte 24/7
- Implementação assistida
- Treinamento da equipe
- Consultoria de processos

**Valor:** Sob consulta (cotação personalizada)

---

## 5. ROADMAP DE FUNCIONALIDADES FUTURAS

### Fase 1 - Portal do Paciente (6-12 meses)
- Login do paciente
- Visualização de agendamentos
- Agendamento online
- Histórico de sessões
- Acesso a documentos
- Acesso a materiais terapêuticos
- Diário terapêutico pessoal
- Registro de humor/sintomas
- Tarefas terapêuticas
- Mensagens com terapeuta
- Pagamentos online
- Histórico financeiro

### Fase 2 - Recursos Avançados (12-18 meses)
- Teleatendimento integrado (videochamada nativa)
- Gravação de sessões (com consentimento)
- Transcrição automática
- Inteligência artificial para sugestões
- Análise de sentimento
- Detecção de padrões
- Alertas preditivos (risco de abandono)
- Recomendação de intervenções
- Grupo terapêutico online
- Chat em grupo
- Fórum de pacientes
- Gamificação do tratamento

### Fase 3 - Integrações Avançadas (18-24 meses)
- Integração com wearables (smartwatch)
- Monitoramento de sono
- Monitoramento de atividade física
- Frequência cardíaca
- Integração com apps de meditação
- Integração com apps de humor
- Integração com plataformas de pagamento
- Integração com emissores de NF
- Integração com convênios
- API aberta para terceiros

### Fase 4 - Pesquisa e Ciência (24+ meses)
- Anonimização de dados para pesquisa
- Relatórios científicos
- Análise de efetividade de tratamentos
- Benchmarking anônimo
- Contribuição para estudos
- Base de conhecimento colaborativa
- Casos clínicos anonimizados
- Protocolos baseados em evidências

---

## 6. CONSIDERAÇÕES TÉCNICAS

### 6.1 Arquitetura Sugerida
- **Backend:** Golang
- **Frontend:** Flutter (Web e Mobile)
- **Banco de Dados:** PostgreSQL
- **Cache:** Redis (a ser implementado futuramente)
- **Armazenamento:** AWS S3 / Google Cloud Storage
- **Autenticação:** JWT + OAuth2
- **API:** REST
- **Real-time:** WebSockets
- **Fila de Mensagens:** RabbitMQ/Kafka

### 6.2 Segurança
- Criptografia em todas as camadas
- Certificado SSL/TLS
- WAF (Web Application Firewall)
- DDoS protection
- Rate limiting
- Input validation
- SQL injection protection
- XSS protection
- CSRF tokens
- Penetration testing regular

### 6.3 Escalabilidade
- Arquitetura de microserviços
- Load balancing
- Auto-scaling
- CDN para assets estáticos
- Cache distribuído
- Database sharding
- Filas assíncronas
- Serverless functions

### 6.4 Monitoramento
- Application Performance Monitoring (APM)
- Log aggregation
- Error tracking
- Uptime monitoring
- Analytics de uso
- Alertas automatizados
- Dashboard de infraestrutura

---

## 7. DIFERENCIAIS COMPETITIVOS

### 7.1 Perfil Comportamental Inteligente
- Sistema proprietário de classificação
- Aprendizado ao longo do tratamento
- Sugestões personalizadas de abordagem
- Visualizações intuitivas
- Evolução temporal do perfil

### 7.2 Analytics Preditivo
- Identificação de pacientes em risco
- Previsão de abandono
- Otimização de agenda
- Sugestões de intervenções
- Melhores horários por paciente

### 7.3 Experiência do Usuário
- Interface limpa e intuitiva
- Mobile-first
- Offline-first (sincronização)
- Carregamento rápido
- Acessibilidade (WCAG)
- Suporte a voz (ditado)

### 7.4 Conformidade e Ética
- 100% em conformidade com CFP
- LGPD compliant
- Transparência total
- Controle do paciente sobre seus dados
- Ética como prioridade

### 7.5 Comunidade e Conhecimento
- Base de conhecimento
- Fórum de terapeutas
- Webinars e treinamentos
- Material educativo
- Casos de sucesso
- Boas práticas

---

## 8. MÉTRICAS DE SUCESSO

### 8.1 Para o Terapeuta
- Redução de tempo administrativo (meta: 50%)
- Aumento de pacientes ativos (meta: 30%)
- Melhoria na taxa de comparecimento (meta: 90%)
- Redução de inadimplência (meta: 5%)
- Satisfação do terapeuta (NPS > 50)

### 8.2 Para o Paciente
- Facilidade de agendamento
- Comunicação efetiva
- Acesso a materiais
- Transparência financeira
- Satisfação com atendimento (NPS > 70)

### 8.3 Para o Negócio
- Taxa de conversão free → pago (meta: 10%)
- Churn rate (meta: < 5% ao mês)
- LTV (Lifetime Value) > 12 meses
- CAC (Customer Acquisition Cost) recuperado em 6 meses
- Crescimento MRR (Monthly Recurring Revenue) 15% ao mês

---

## 9. GLOSSÁRIO DE TERMOS

**Anamnese:** Primeira entrevista detalhada para coleta de histórico do paciente

**Prontuário:** Registro completo do histórico clínico e evolução do tratamento

**Evolução:** Anotações sobre o progresso do paciente ao longo do tempo

**Plano Terapêutico:** Planejamento estruturado de objetivos e intervenções

**Perfil Comportamental:** Classificação de características e padrões de comportamento

**Intercorrência:** Evento inesperado durante o tratamento

**Alta:** Encerramento do tratamento

**Gatilho:** Estímulo que desencadeia reação emocional/comportamental

**Homework:** Tarefas terapêuticas para o paciente realizar entre sessões

**Setting:** Ambiente e configuração da relação terapêutica

**Rapport:** Vínculo de confiança entre terapeuta e paciente

**CRP:** Conselho Regional de Psicologia

**CFP:** Conselho Federal de Psicologia

**LGPD:** Lei Geral de Proteção de Dados

**NPS:** Net Promoter Score (métrica de satisfação)

**MRR:** Monthly Recurring Revenue (receita recorrente mensal)

**Churn:** Taxa de cancelamento/abandono

**LTV:** Lifetime Value (valor vitalício do cliente)

**CAC:** Customer Acquisition Cost (custo de aquisição de cliente)

---

## 10. PRÓXIMOS PASSOS

### Modelagem Técnica
1. Diagrama Entidade-Relacionamento (DER)
2. Diagrama de Classes (UML)
3. Casos de Uso
4. User Stories
5. Wireframes
6. Protótipo navegável

### Validação
1. Entrevistas com terapeutas
2. Teste de conceito
3. MVP (Minimum Viable Product)
4. Beta testing
5. Iterações baseadas em feedback

### Desenvolvimento
1. Sprint 0 - Setup e arquitetura
2. Sprint 1-3 - Módulo de cadastros
3. Sprint 4-6 - Módulo de agenda e sessões
4. Sprint 7-9 - Módulo de prontuário e evolução
5. Sprint 10-12 - Módulo financeiro
6. Sprint 13-15 - Perfil comportamental
7. Sprint 16-18 - Analytics e relatórios
8. Sprint 19-21 - Documentos e comunicação
9. Sprint 22-24 - Polimento e testes
10. Sprint 25 - Launch

---

## CONCLUSÃO

Este documento apresenta uma visão abrangente das entidades de negócio necessárias para um sistema completo de gerenciamento clínico para terapeutas. O diferencial competitivo está no **sistema de perfil comportamental inteligente** e na **experiência personalizada** tanto para o terapeuta quanto para o paciente.

O modelo de negócio freemium com três planos permite atrair usuários e escalar conforme suas necessidades crescem, mantendo a sustentabilidade financeira do projeto.

A próxima etapa crítica é **explorar e definir em detalhes o sistema de perfis comportamentais**, que será o coração diferenciador da plataforma.

---

**Documento criado em:** Outubro 2025  
**Versão:** 1.0  
**Status:** Proposta Inicial


Agora estou pronto para explorar com você o sistema de perfis comportamentais em detalhes! Posso criar:

Modelos de classificação (DISC, Big Five, Eneagrama ou customizado)
Sistema de pontuação e avaliação
Visualizações e dashboards do perfil
Algoritmos de recomendação de estratégias terapêuticas
Evolução temporal dos perfis
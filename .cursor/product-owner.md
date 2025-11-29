# Rule: Product Owner - Sistema de Gerenciamento para Terapeutas

Você está desenvolvendo um sistema de gerenciamento de trabalho para terapeutas. Este é um domínio altamente especializado que envolve saúde, sigilo profissional e regulamentações específicas.

## Conhecimento Obrigatório do Domínio

### Fluxo de Atendimento Terapêutico
- **Triagem inicial**: Primeira avaliação, coleta de dados básicos, avaliação de urgência
- **Anamnese**: Histórico clínico detalhado, familiar, social e de desenvolvimento
- **Objetivos terapêuticos**: Metas de curto, médio e longo prazo definidas com o paciente
- **Plano de tratamento**: Frequência de sessões, abordagem terapêutica, duração estimada
- **Evolução**: Registro contínuo de progresso e ajustes no tratamento
- **Alta terapêutica**: Critérios de encerramento e processo estruturado

### Gestão de Sessões
- Sessões padrão de 45-50 minutos com intervalos obrigatórios
- Preparação pré-sessão: revisão de notas anteriores e planejamento
- Documentação: pode ser durante ou imediatamente após a sessão
- Prontuário obrigatório com evolução clínica detalhada
- Termos de consentimento e documentos legais

### Classificações e Diagnósticos
- **CID-10/CID-11**: Classificação Internacional de Doenças (obrigatório para convênios)
- **DSM-5**: Manual Diagnóstico e Estatístico (usado por psicólogos e psiquiatras)
- **Triagem de risco**: Identificação de ideação suicida, crises agudas, urgências
- **Categorização**: Por complexidade, abordagem, faixa etária, tipo de demanda

### Aspectos Administrativos
- **Agendamento**: Gestão de horários, remarcações, cancelamentos, lista de espera
- **Cobrança**: Convênios médicos, particular, emissão de recibos e notas fiscais
- **Comunicação**: Limites éticos de contato com pacientes (apenas emergências fora do horário)
- **Documentação**: Guarda segura conforme LGPD e tempo mínimo de 5 anos

### Desafios Específicos
- Interrupções não planejadas: crises entre sessões, emergências
- Encaminhamentos: para psiquiatras, neurologistas, outros especialistas
- Supervisão clínica: discussão de casos complexos com supervisores
- Gerenciamento de casos de risco: protocolos de segurança

## Aspectos Éticos e Legais CRÍTICOS

### Sigilo Profissional
- Dados de saúde são EXTREMAMENTE sensíveis
- Nem tudo pode/deve ser registrado digitalmente
- Acesso restrito absoluto ao prontuário
- Criptografia de ponta a ponta obrigatória

### Conformidade Legal
- **LGPD**: Lei Geral de Proteção de Dados - categoria especial para saúde
- **Conselhos profissionais**: CFP (Psicologia), CFM (Medicina), COFFITO (Fisioterapia), etc.
- **Resolução CFP 11/2018**: Regulamenta prestação de serviços psicológicos online
- **Prontuário**: Obrigatoriedade legal de manutenção por no mínimo 5 anos

### Proteção de Dados
- Backup criptografado obrigatório
- Logs de acesso auditáveis
- Termo de consentimento para uso de dados digitais
- Direito ao esquecimento e portabilidade de dados

## Regras de Desenvolvimento

### SEMPRE considerar
1. **Sigilo em primeiro lugar**: Qualquer feature deve ser avaliada sob ótica de proteção de dados
2. **Minimize trabalho administrativo**: Terapeutas precisam maximizar tempo clínico
3. **Fluxo natural**: Sistema deve seguir o fluxo real de trabalho, não impor novos processos
4. **Offline-first**: Terapeuta pode precisar acessar informações sem internet
5. **Mobile-friendly**: Muitos terapeutas trabalham em consultórios sem computador fixo

### NUNCA implementar
1. Features que exponham dados sensíveis desnecessariamente
2. Compartilhamentos automáticos sem consentimento explícito
3. Integrações com terceiros sem avaliar impacto no sigilo
4. Campos obrigatórios que não sejam essenciais legalmente
5. Processos que aumentem burocracia sem valor clínico

### Validação de Features
Antes de priorizar qualquer feature, pergunte:
- Isso protege adequadamente o sigilo do paciente?
- Isso economiza ou consome tempo do terapeuta?
- Isso está em conformidade com conselhos profissionais?
- Isso facilita o trabalho clínico ou apenas o administrativo?
- Terapeutas realmente precisam disso ou é nossa suposição?

## Conhecimento Validado

O PO deve comprovar:
- Job shadowing com no mínimo 3 terapeutas diferentes (1 semana cada)
- Entrevistas com pelo menos 10 profissionais sobre dores e fluxos
- Mapeamento de 3 jornadas completas de pacientes (triagem à alta)
- Estudo das regulamentações do conselho profissional e LGPD para saúde

## Consequências de Não Seguir Esta Rule

Um sistema mal desenhado pode:
- Comprometer sigilo profissional (violação ética grave)
- Criar trabalho administrativo que prejudica tempo clínico
- Não atender exigências legais (multas, processos)
- Prejudicar qualidade do atendimento aos pacientes
- Ser rejeitado pelos terapeutas (desperdício de investimento)

## Lembrete Final

**Você está lidando com saúde mental e dados sensíveis. O impacto de erros vai além do técnico - pode afetar vidas. Quando em dúvida, priorize sempre: SIGILO > SIMPLICIDADE > CONFORMIDADE > FEATURES.**
# Próximos Passos - Sistema de Anamnese

## ✅ O que já foi implementado

### Backend (100% Completo)
- ✅ Migrations para tabelas `anamnesis` e `anamnesis_templates`
- ✅ Models Dart (`Anamnesis` e `AnamnesisTemplate`)
- ✅ Repository com CRUD completo
- ✅ Controller com lógica de negócio
- ✅ Handler com endpoints HTTP
- ✅ Routes integradas ao servidor
- ✅ Template padrão do sistema (13 seções, ~70 campos)
- ✅ Testes automatizados (unitários e integração)
- ✅ Scripts para inserir template padrão

### Documentação
- ✅ Modelo de template documentado
- ✅ Guia de testes da API
- ✅ README dos templates

---

## 🎯 Próximos Passos - Priorizados

### FASE 1: Integração Frontend-Backend (Alta Prioridade)

#### 1.1 Atualizar/Criar Models Completos no Frontend
**Prioridade:** 🔴 Alta  
**Complexidade:** Baixa-Média  
**Tempo estimado:** 2-3 horas

**Situação Atual:**
- ✅ Existe `AnamnesisData` básico (apenas alguns campos hardcoded)
- ❌ Precisa criar models completos que correspondam ao backend

**Tarefas:**
- [ ] Criar model `Anamnesis` completo (correspondente ao backend)
- [ ] Criar model `AnamnesisTemplate` completo
- [ ] Criar model `AnamnesisField` para campos dinâmicos
- [ ] Manter `AnamnesisData` para compatibilidade ou migrar
- [ ] Adicionar mappers para converter JSON ↔ Models

**Arquivos a criar/modificar:**
```
app/lib/features/anamnesis/
├── models/
│   ├── anamnesis.dart (novo, completo)
│   ├── anamnesis_template.dart (novo)
│   ├── anamnesis_field.dart (novo)
│   └── anamnesis_section.dart (novo)
```

#### 1.2 Criar Repositories no Frontend
**Prioridade:** 🔴 Alta  
**Complexidade:** Baixa  
**Tempo estimado:** 2-3 horas

**Tarefas:**
- [ ] Criar `AnamnesisRepository` (interface)
- [ ] Criar `AnamnesisRepositoryImpl` (implementação com HTTP)
- [ ] Criar `AnamnesisTemplateRepository` (interface)
- [ ] Criar `AnamnesisTemplateRepositoryImpl` (implementação)
- [ ] Integrar no `DependencyContainer`

**Arquivos a criar:**
```
app/lib/core/
├── domain/repositories/
│   ├── anamnesis_repository.dart
│   └── anamnesis_template_repository.dart
└── data/repositories/
    ├── anamnesis_repository_impl.dart
    └── anamnesis_template_repository_impl.dart
```

---

#### 1.2 Criar BLoC para Anamnese
**Prioridade:** 🔴 Alta  
**Complexidade:** Média  
**Tempo estimado:** 3-4 horas

**Tarefas:**
- [ ] Criar `AnamnesisBloc` com estados e eventos
- [ ] Implementar busca de anamnese por paciente
- [ ] Implementar criação/atualização de anamnese
- [ ] Implementar busca de templates disponíveis
- [ ] Tratamento de erros e loading states

**Arquivos a criar:**
```
app/lib/features/anamnesis/
└── bloc/
    ├── anamnesis_bloc.dart
    └── anamnesis_bloc_models.dart
```

---

#### 1.3 Substituir Step5 Anamnese Básico pelo Sistema Completo
**Prioridade:** 🔴 Alta  
**Complexidade:** Alta  
**Tempo estimado:** 8-12 horas

**Tarefas:**
- [ ] Remover/refatorar `step5_anamnesis.dart` atual
- [ ] Criar widget dinâmico que renderiza campos baseado no template
- [ ] Implementar renderização de todos os tipos de campo:
  - [ ] text
  - [ ] textarea
  - [ ] number
  - [ ] slider
  - [ ] boolean
  - [ ] select
  - [ ] radio
  - [ ] checkbox_group
  - [ ] date
  - [ ] rating
- [ ] Implementar campos condicionais
- [ ] Validação de campos obrigatórios
- [ ] Salvar dados no formato JSONB correto
- [ ] Integrar com API ao salvar paciente

**Arquivos a criar/modificar:**
```
app/lib/features/anamnesis/
├── pages/
│   └── anamnesis_form_page.dart (novo, completo)
└── widgets/
    ├── anamnesis_section_widget.dart
    ├── anamnesis_field_widget.dart
    └── conditional_field_wrapper.dart
```

---

### FASE 2: Funcionalidades Essenciais (Média Prioridade)

#### 2.1 Atualizar Visualização de Anamnese Existente
**Prioridade:** 🟡 Média  
**Complexidade:** Média  
**Tempo estimado:** 4-6 horas

**Situação Atual:**
- ✅ Existe `_buildAnamnesisInfo()` no `patient_dashboard_page.dart`
- ❌ Está mostrando dados mockados/hardcoded
- ❌ Precisa buscar dados reais da API

**Tarefas:**
- [ ] Buscar anamnese real da API no dashboard do paciente
- [ ] Atualizar `_buildAnamnesisInfo()` para renderizar dados reais
- [ ] Renderizar seções dinamicamente baseado no template
- [ ] Mostrar seções colapsáveis
- [ ] Destacar campos preenchidos
- [ ] Mostrar progresso de completude
- [ ] Tratar caso de anamnese não preenchida (botão para preencher)

**Arquivos a modificar:**
```
app/lib/features/patients/
└── patient_dashboard_page.dart (atualizar _buildAnamnesisInfo)
```

---

#### 2.2 Edição de Anamnese Existente
**Prioridade:** 🟡 Média  
**Complexidade:** Média  
**Tempo estimado:** 4-6 horas

**Tarefas:**
- [ ] Permitir editar anamnese já preenchida
- [ ] Carregar dados existentes no formulário
- [ ] Mostrar histórico de alterações (se implementado)
- [ ] Marcar como completa ao finalizar

**Arquivos a modificar:**
```
app/lib/features/anamnesis/
└── pages/
    └── anamnesis_form_page.dart (adicionar modo edição)
```

---

#### 2.3 Gerenciamento de Templates
**Prioridade:** 🟢 Baixa (Deixar para depois)  
**Complexidade:** Alta  
**Tempo estimado:** 8-10 horas

**Decisão:** Gerenciamento de templates será feito em interface web dedicada (mais adequado para edição complexa de JSON/estrutura)

**Tarefas (Futuro - Web):**
- [ ] Interface web para gerenciar templates
- [ ] Editor visual de estrutura de template
- [ ] Preview de template
- [ ] Validação de estrutura

**Nota:** No app mobile, apenas:
- [ ] Listar templates disponíveis (read-only)
- [ ] Selecionar template para usar

---

### FASE 3: Melhorias e Refinamentos (Baixa Prioridade)

#### 3.1 Validação Avançada
**Prioridade:** 🟢 Baixa  
**Complexidade:** Média  
**Tempo estimado:** 4-6 horas

**Tarefas:**
- [ ] Validação de campos obrigatórios em tempo real
- [ ] Validação de formatos (email, CPF, etc.)
- [ ] Validação de ranges (min/max)
- [ ] Mensagens de erro personalizadas
- [ ] Indicador de progresso de preenchimento

---

#### 3.2 Campos Condicionais Avançados
**Prioridade:** 🟢 Baixa  
**Complexidade:** Alta  
**Tempo estimado:** 6-8 horas

**Tarefas:**
- [ ] Suporte a múltiplas condições (AND/OR)
- [ ] Condições baseadas em campos de outras seções
- [ ] Animações suaves ao mostrar/ocultar campos
- [ ] Validação de campos condicionais

---

#### 3.3 UX/UI Melhorias
**Prioridade:** 🟢 Baixa  
**Complexidade:** Baixa-Média  
**Tempo estimado:** 4-6 horas

**Tarefas:**
- [ ] Indicador de progresso visual
- [ ] Seções colapsáveis
- [ ] Salvar rascunho automaticamente
- [ ] Navegação entre seções
- [ ] Ajuda contextual (tooltips)
- [ ] Modo offline (salvar localmente e sincronizar depois)

---

#### 3.4 Integração com Cadastro de Paciente
**Prioridade:** 🟡 Média  
**Complexidade:** Média  
**Tempo estimado:** 3-4 horas

**Tarefas:**
- [ ] Integrar formulário de anamnese no cadastro de paciente
- [ ] Opção de preencher anamnese durante cadastro ou depois
- [ ] Salvar anamnese ao criar paciente
- [ ] Link para preencher anamnese depois no dashboard do paciente

---

## 📋 Checklist de Implementação Sugerida

### Sprint 1 (Semana 1-2)
- [ ] 1.1 - Atualizar/Criar Models Completos
- [ ] 1.2 - Criar Repositories
- [ ] 1.3 - Criar BLoC para Anamnese
- [ ] Testes básicos de integração

### Sprint 2 (Semana 3-4)
- [ ] 1.4 - Formulário dinâmico completo
- [ ] Renderização de todos os tipos de campo
- [ ] Campos condicionais básicos
- [ ] Integração com cadastro de paciente

### Sprint 3 (Semana 5-6)
- [ ] 2.1 - Atualizar visualização existente (buscar dados reais)
- [ ] 2.2 - Edição de anamnese
- [ ] Melhorias de UX/UI

### Sprint 4 (Semana 7-8)
- [ ] Validação avançada
- [ ] Campos condicionais avançados
- [ ] Polimento e testes
- [ ] **Gerenciamento de templates (Web)** - Futuro

---

## 🎨 Considerações de Design

### Formulário de Anamnese
- **Layout:** Wizard multi-step ou página única com seções colapsáveis
- **Navegação:** Barra lateral com índice de seções
- **Progresso:** Barra de progresso no topo
- **Salvamento:** Auto-save a cada X segundos + botão salvar manual
- **Validação:** Feedback visual imediato

### Visualização
- **Layout:** Cards por seção
- **Destaque:** Campos importantes em destaque
- **Exportação:** Opção de exportar para PDF (futuro)

---

## 🔧 Dependências Técnicas

### Pacotes Flutter que podem ser úteis:
- `flutter_form_builder` - Para formulários dinâmicos
- `json_serializable` - Para serialização JSON
- `equatable` - Para comparação de objetos
- `freezed` - Para modelos imutáveis (opcional)

---

## 📊 Métricas de Sucesso

### Funcionalidade
- ✅ Formulário renderiza todos os tipos de campo corretamente
- ✅ Campos condicionais funcionam
- ✅ Validação impede submissão com dados inválidos
- ✅ Dados são salvos corretamente no backend

### Performance
- ⚡ Formulário carrega em < 2 segundos
- ⚡ Navegação entre seções é fluida
- ⚡ Auto-save não bloqueia a UI

### UX
- 👤 Terapeuta consegue preencher anamnese completa em < 15 minutos
- 👤 Interface intuitiva, sem necessidade de treinamento
- 👤 Feedback claro sobre progresso e validações

---

## 🚀 Começando Agora

### Próximo passo imediato:
1. **Criar estrutura básica no frontend:**
   ```bash
   mkdir -p app/lib/features/anamnesis/{models,bloc,pages,widgets}
   mkdir -p app/lib/core/{domain,data}/repositories
   ```

2. **Criar models completos:**
   - `anamnesis.dart` (correspondente ao backend)
   - `anamnesis_template.dart`
   - `anamnesis_field.dart` e `anamnesis_section.dart`

3. **Criar repositories:**
   - Interface em `core/domain/repositories/`
   - Implementação em `core/data/repositories/`
   - Integrar no `DependencyContainer`

4. **Criar BLoC básico:**
   - Estados e eventos
   - Buscar templates disponíveis
   - Buscar anamnese por paciente
   - Criar/atualizar anamnese

---

## 📝 Notas Importantes

1. **Compatibilidade:** 
   - O `step5_anamnesis.dart` atual é muito básico (apenas alguns campos hardcoded)
   - Precisamos substituí-lo completamente pelo sistema novo baseado em templates
   - Manter `AnamnesisData` para compatibilidade durante transição ou migrar

2. **Visualização Existente:**
   - `_buildAnamnesisInfo()` no `patient_dashboard_page.dart` existe mas mostra dados mockados
   - Precisa ser atualizado para buscar dados reais da API
   - Renderizar dinamicamente baseado no template

3. **Gerenciamento de Templates:**
   - **Decisão:** Fazer em interface web (mais adequado para edição complexa)
   - No app mobile: apenas listar e selecionar templates (read-only)

4. **Migração de Dados:** Se houver anamneses antigas no formato antigo, precisaremos criar um script de migração.

5. **Templates Futuros:** Pensar em como adicionar templates para crianças, casais, etc.

6. **Portal do Paciente:** Quando implementarmos, o paciente poderá preencher a anamnese. Manter isso em mente no design.

---

## 🎯 Priorização Final (Ajustada)

**Ordem recomendada de implementação:**

1. ✅ **Backend** (JÁ FEITO)
2. 🔴 **Models Completos Frontend** (PRÓXIMO)
   - Criar models que correspondem ao backend
   - Manter compatibilidade com `AnamnesisData` existente
3. 🔴 **Repositories Frontend**
   - Criar repositories seguindo padrão do projeto
   - Integrar no DependencyContainer
4. 🔴 **BLoC Frontend**
   - Criar bloc para gerenciar estado
   - Buscar templates e anamneses
5. 🔴 **Formulário Dinâmico Completo**
   - Substituir `step5_anamnesis.dart` básico
   - Renderizar campos baseado no template
6. 🟡 **Atualizar Visualização Existente**
   - Buscar dados reais da API
   - Renderizar dinamicamente
7. 🟡 **Edição de Anamnese**
   - Permitir editar anamnese existente
8. 🟢 **Melhorias e Refinamentos**
   - Validação avançada
   - Campos condicionais avançados
   - UX/UI melhorias
9. 🔵 **Gerenciamento de Templates (Web)** - Futuro
   - Interface web dedicada
   - Editor visual de templates

---

**Última atualização:** Janeiro 2025  
**Status:** Backend completo, Frontend pendente


# 🧪 Como Rodar os Testes - Guia Completo

Este guia explica como executar todos os tipos de testes do projeto Terafy.

## 📋 Índice

1. [Testes Rápidos](#testes-rápidos)
2. [Testes do Backend](#testes-do-backend)
3. [Testes do Frontend](#testes-do-frontend)
4. [Testes de Integração](#testes-de-integração)
5. [Cobertura de Código](#cobertura-de-código)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Testes Rápidos

### Executar Todos os Testes (Backend + Frontend)

```bash
# Na raiz do projeto
./scripts/run-all-tests.sh
```

Este comando executa:
- ✅ Todos os testes do backend
- ✅ Todos os testes do frontend
- ✅ Validação de cobertura mínima (80%)
- ✅ Geração de relatórios LCOV

**Tempo estimado:** 2-5 minutos

---

## 📦 Testes do Backend

### Todos os Testes do Backend

```bash
# Opção 1: Script automatizado (recomendado)
./deploy/run-backend-tests.sh

# Opção 2: Comando direto
cd server
dart pub get
dart test
```

### Testes Específicos

```bash
cd server

# Testes de uma feature específica
dart test test/features/therapist/ --fail-fast
dart test test/features/schedule/ --fail-fast
dart test test/features/auth/ --fail-fast
dart test test/features/patient/ --fail-fast
dart test test/features/session/ --fail-fast
dart test test/features/financial/ --fail-fast

# Todas as features
dart test test/features/ --fail-fast

# Teste de um arquivo específico
dart test test/features/therapist/therapist.repository_test.dart

# Testes de repository
dart test test/features/*/**.repository_test.dart

# Testes de controller
dart test test/features/*/**.controller_test.dart

# Testes de handler
dart test test/features/*/**.handler_test.dart

# Testes de integração
dart test test/features/*/**.integration_test.dart
```

### Testes com Cobertura

```bash
cd server
dart test --coverage=coverage
```

### Ver Relatório de Cobertura

```bash
cd server

# Gerar relatório LCOV
dart pub global activate coverage
dart pub global run coverage:format_coverage \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info \
    --packages=.dart_tool/package_config.json \
    --report-on=lib

# Gerar HTML (requer lcov instalado)
brew install lcov  # macOS
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📱 Testes do Frontend

### Todos os Testes do Frontend

```bash
# Opção 1: Script automatizado (recomendado)
./deploy/run-frontend-tests.sh

# Opção 2: Comando direto
cd app
flutter pub get
flutter test
```

### Testes Específicos

```bash
cd app

# Testes de uma feature específica
flutter test test/features/home/

# Teste de um arquivo específico
flutter test test/features/home/bloc/home_bloc_test.dart

# Testes de BLoCs
flutter test test/features/*/bloc/*_bloc_test.dart

# Testes de widgets
flutter test test/features/*/widgets/*_widgets_test.dart
```

### Testes com Cobertura

```bash
cd app
flutter test --coverage
```

### Ver Relatório de Cobertura

```bash
cd app

# O Flutter já gera lcov.info automaticamente
# Para visualizar HTML (requer lcov instalado)
brew install lcov  # macOS
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🔗 Testes de Integração

### Testes de Integração do Backend

Os testes de integração do backend usam um banco de dados PostgreSQL real.

**Pré-requisitos:**
- PostgreSQL rodando
- Banco de dados de teste configurado
- Variáveis de ambiente configuradas

```bash
cd server

# Executar todos os testes de integração
dart test test/features/*/**.integration_test.dart

# Executar teste específico
dart test test/features/therapist/therapist.integration_test.dart
```

### Testes de Integração do Frontend

Os testes de integração do frontend testam fluxos completos end-to-end.

**Pré-requisitos:**
- Backend rodando (`make server-dev`)
- Usuário de teste criado (`make create-test-user`)
- Dispositivo/emulador conectado

```bash
cd app

# Listar dispositivos disponíveis
flutter devices

# Executar todos os testes de integração
flutter test integration_test/

# Executar teste específico
flutter test integration_test/login_visual_test.dart

# Executar em dispositivo específico
flutter test integration_test/login_visual_test.dart -d chrome
flutter test integration_test/login_visual_test.dart -d macos
flutter test integration_test/login_visual_test.dart -d emulator-5554
```

### Testes de Integração Rápidos (com --no-pub)

Para acelerar testes durante desenvolvimento:

```bash
cd app
flutter test integration_test/login_visual_test.dart --no-pub
```

**⚠️ Nota:** Use `--no-pub` apenas se as dependências não mudaram.

---

## 📊 Cobertura de Código

### Gerar Relatórios Completos

```bash
# Na raiz do projeto
./scripts/generate-coverage-report.sh
```

Este script:
- ✅ Executa testes com cobertura (backend + frontend)
- ✅ Gera relatórios LCOV
- ✅ Gera relatórios HTML (se lcov estiver instalado)
- ✅ Valida threshold mínimo (80%)
- ✅ Exibe resumo de cobertura

### Ver Cobertura por Feature

Para ver a cobertura detalhada por feature/diretório:

```bash
# Backend
./scripts/show-coverage-by-feature.sh backend

# Frontend
./scripts/show-coverage-by-feature.sh frontend
```

Este comando mostra uma tabela com:
- Cobertura de cada feature (auth, therapist, financial, etc.)
- Número de arquivos e linhas cobertas
- Porcentagem de cobertura com indicadores visuais:
  - ✅ 80% ou mais
  - ⚠️  Entre 50% e 79%
  - ❌ Menos de 50%

### Visualizar Relatórios HTML

Para visualizar relatórios HTML completos (requer `lcov`):

```bash
# Instalar lcov (se necessário)
brew install lcov  # macOS
sudo apt-get install lcov  # Linux

# Gerar relatórios HTML
./scripts/generate-coverage-report.sh

# Abrir relatórios
open coverage-reports/backend/html/index.html
open coverage-reports/frontend/html/index.html

# Ou gerar manualmente
cd server
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Threshold Mínimo

O projeto exige **mínimo de 80% de cobertura**. Os scripts validam automaticamente:

```bash
# Backend - falha se cobertura < 80%
./deploy/run-backend-tests.sh

# Frontend - falha se cobertura < 80%
./deploy/run-frontend-tests.sh
```

---

## 🎯 Comandos Úteis

### Executar Testes em Modo Watch (Backend)

```bash
cd server
dart test --watch
```

### Executar Testes em Modo Watch (Frontend)

```bash
cd app
flutter test --watch
```

### Executar Apenas Testes que Falharam

```bash
# Backend
cd server
dart test --reporter expanded

# Frontend
cd app
flutter test --reporter expanded
```

### Executar Testes com Output Detalhado

```bash
# Backend
cd server
dart test --reporter expanded

# Frontend
cd app
flutter test --verbose
```

### Executar Teste Específico por Nome

```bash
# Backend
cd server
dart test --name "deve criar therapist com dados válidos"

# Frontend
cd app
flutter test --plain-name "renderiza campos de email e senha"
```

---

## 🔧 Integração Automática

### Git Hook (Pre-Push)

Os testes são executados automaticamente antes de cada push:

```bash
git push
# Os testes rodam automaticamente
```

**Pular testes (não recomendado):**
```bash
SKIP_TESTS=1 git push
```

### Build/Deploy

Os testes são executados automaticamente antes do build:

```bash
./deploy/prepare-deploy.sh
# PASSO 0: Executa todos os testes
# Se falharem, o build é abortado
```

---

## 🐛 Troubleshooting

### Erro: "Dart/Flutter não encontrado"

```bash
# Verificar instalação
dart --version
flutter --version

# Adicionar ao PATH (se necessário)
export PATH="$PATH:/path/to/dart/bin"
export PATH="$PATH:/path/to/flutter/bin"
```

### Erro: "Dependências não encontradas"

```bash
# Backend
cd server
dart pub get

# Frontend
cd app
flutter pub get
```

### Erro: "Testes de integração falhando"

**Backend:**
- Verificar se PostgreSQL está rodando
- Verificar variáveis de ambiente em `.env`
- Verificar se banco de teste existe

**Frontend:**
- Verificar se backend está rodando: `make server-dev`
- Criar usuário de teste: `make create-test-user`
- Verificar dispositivo conectado: `flutter devices`

### Erro: "Cobertura abaixo do mínimo"

```bash
# Ver relatório detalhado
./scripts/generate-coverage-report.sh

# Identificar arquivos sem cobertura
open coverage-reports/backend/html/index.html
open coverage-reports/frontend/html/index.html

# Adicionar testes para aumentar cobertura
```

### Erro: "Timeout em testes de integração"

Aumentar timeout nos testes:

```dart
// No arquivo de teste
await tester.pumpAndSettle(const Duration(seconds: 10));
```

### Limpar Cache e Reexecutar

```bash
# Backend
cd server
dart pub cache repair
dart pub get
dart test

# Frontend
cd app
flutter clean
flutter pub get
flutter test
```

---

## 📚 Estrutura de Testes

### Backend

```
server/test/
├── features/
│   ├── auth/
│   │   ├── auth.controller_test.dart
│   │   ├── auth.handler_test.dart
│   │   └── auth.integration_test.dart
│   ├── therapist/
│   │   ├── therapist.repository_test.dart
│   │   ├── therapist.controller_test.dart
│   │   ├── therapist.handler_test.dart
│   │   └── therapist.integration_test.dart
│   └── ...
└── helpers/
```

### Frontend

```
app/test/
├── features/
│   ├── login/
│   │   ├── bloc/login_bloc_test.dart
│   │   └── widgets/login_form_widget_test.dart
│   ├── home/
│   │   ├── bloc/home_bloc_test.dart
│   │   └── widgets/home_widgets_test.dart
│   └── ...
app/integration_test/
├── login_visual_test.dart
├── patients_integration_test.dart
└── ...
```

---

## ✅ Checklist Antes de Fazer Push

- [ ] Todos os testes passam localmente
- [ ] Cobertura está acima de 80%
- [ ] Não há warnings do linter
- [ ] Testes de integração passam (se aplicável)
- [ ] Documentação está atualizada

---

## 📖 Recursos Adicionais

- [Documentação Completa de Testes](./TESTING.md)
- [Dart Testing Guide](https://dart.dev/guides/testing)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)

---

## 💡 Dicas

1. **Use scripts automatizados**: Prefira `./scripts/run-all-tests.sh` ao invés de comandos manuais
2. **Teste antes de commitar**: Execute testes localmente antes de fazer push
3. **Mantenha cobertura alta**: Adicione testes para novas features
4. **Use watch mode**: Durante desenvolvimento, use `--watch` para testes automáticos
5. **Valide integração**: Sempre teste fluxos completos após mudanças significativas

---

**Última atualização:** Dezembro 2024

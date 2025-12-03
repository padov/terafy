# 🧪 Guia de Testes - Terafy

Este documento descreve como executar e gerenciar os testes automatizados do projeto Terafy.

## 📋 Estrutura de Testes

### Backend (`server/test/`)
- **Repositories**: Testes de acesso a dados
- **Controllers**: Testes de lógica de negócio
- **Handlers**: Testes de endpoints HTTP
- **Integration**: Testes de integração com banco real

### Frontend (`app/test/`)
- **BLoCs**: Testes de gerenciamento de estado
- **Widgets**: Testes de componentes UI
- **Integration**: Testes end-to-end

## 🚀 Executando Testes

### Todos os Testes

```bash
# Executa testes do backend e frontend
./scripts/run-all-tests.sh
```

### Apenas Backend

```bash
# Executa testes do backend
./deploy/run-backend-tests.sh
```

### Apenas Frontend

```bash
# Executa testes do frontend
./deploy/run-frontend-tests.sh
```

### Testes Específicos

#### Backend

```bash
cd server
dart test test/features/therapist/therapist.repository_test.dart
```

#### Frontend

```bash
cd app
flutter test test/features/home/bloc/home_bloc_test.dart
```

### Testes de Integração (Frontend)

```bash
cd app
flutter test integration_test/login_visual_test.dart
```

## 🔧 Git Hooks

### Instalação

O git hook `pre-push` é instalado automaticamente e executa todos os testes antes de permitir um push.

Para reinstalar manualmente:

```bash
./scripts/install-git-hooks.sh
```

### Comportamento

O hook `pre-push` irá:
1. Executar testes do backend
2. Executar testes do frontend
3. Bloquear o push se algum teste falhar

### Pular Testes (Não Recomendado)

Em situações excepcionais, você pode pular os testes:

```bash
SKIP_TESTS=1 git push
```

⚠️ **Atenção**: Use apenas em emergências. Testes devem passar antes de fazer push.

## 🏗️ Integração no Build/Deploy

Os testes são executados automaticamente antes do build no script `prepare-deploy.sh`:

```bash
./deploy/prepare-deploy.sh
```

O script irá:
1. **PASSO 0**: Executar todos os testes
2. **PASSO 1**: Build do executável Linux
3. **PASSO 1.5**: Build do Flutter Web
4. **PASSO 2**: Criar pasta de deploy
5. **PASSO 3**: Criar pacote tar.gz

Se os testes falharem, o build será abortado.

## 📊 Cobertura de Código

### Gerar Relatórios Completos

Para gerar relatórios de cobertura completos (backend + frontend) com validação de threshold:

```bash
./scripts/generate-coverage-report.sh
```

Este script irá:
- Executar testes com cobertura para backend e frontend
- Gerar relatórios LCOV
- Gerar relatórios HTML (se `lcov` estiver instalado)
- Validar threshold mínimo de 80%
- Exibir resumo de cobertura

### Backend

```bash
cd server
dart test --coverage=coverage
```

Relatório gerado em: `server/coverage/lcov.info`

Para visualizar HTML (requer `lcov`):
```bash
brew install lcov
genhtml server/coverage/lcov.info -o server/coverage/html
open server/coverage/html/index.html
```

### Frontend

```bash
cd app
flutter test --coverage
```

Relatório gerado em: `app/coverage/lcov.info`

Para visualizar HTML (requer `lcov`):
```bash
brew install lcov
genhtml app/coverage/lcov.info -o app/coverage/html
open app/coverage/html/index.html
```

### Threshold Mínimo

O projeto exige **mínimo de 80% de cobertura** de código. Os scripts de teste validam automaticamente este threshold e falham se a cobertura estiver abaixo do mínimo.

### Relatórios HTML

Os relatórios HTML são gerados em:
- Backend: `coverage-reports/backend/html/index.html`
- Frontend: `coverage-reports/frontend/html/index.html`

Para visualizar:
```bash
open coverage-reports/backend/html/index.html
open coverage-reports/frontend/html/index.html
```

## 🐛 Troubleshooting

### Testes Falhando

1. **Verifique dependências**:
   ```bash
   cd server && dart pub get
   cd app && flutter pub get
   ```

2. **Verifique banco de dados** (para testes de integração):
   - Certifique-se de que o PostgreSQL está rodando
   - Verifique as variáveis de ambiente em `.env`

3. **Limpe cache**:
   ```bash
   cd server && dart pub cache repair
   cd app && flutter clean && flutter pub get
   ```

### Git Hook Não Executando

1. Verifique se o hook existe:
   ```bash
   ls -la .git/hooks/pre-push
   ```

2. Verifique permissões:
   ```bash
   chmod +x .git/hooks/pre-push
   ```

3. Reinstale o hook:
   ```bash
   ./scripts/install-git-hooks.sh
   ```

### Testes de Integração Falhando

1. **Backend não está rodando**:
   ```bash
   make server-dev
   ```

2. **Usuário de teste não existe**:
   ```bash
   make create-test-user
   ```

3. **Timeout muito curto**: Aumente os timeouts nos testes de integração

## 📝 Adicionando Novos Testes

### Backend

1. Crie o arquivo de teste em `server/test/features/[feature]/`
2. Siga o padrão dos testes existentes
3. Execute: `dart test test/features/[feature]/`

### Frontend

1. Crie o arquivo de teste em `app/test/features/[feature]/`
2. Siga o padrão dos testes existentes
3. Execute: `flutter test test/features/[feature]/`

## ✅ Checklist de Qualidade

Antes de fazer push, certifique-se de:

- [ ] Todos os testes passam localmente
- [ ] Cobertura de código está acima de 80%
- [ ] Não há warnings do linter
- [ ] Testes de integração passam
- [ ] Documentação está atualizada

## 📚 Recursos

- [Dart Testing](https://dart.dev/guides/testing)
- [Flutter Testing](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)


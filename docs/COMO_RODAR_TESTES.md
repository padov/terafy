# Como Rodar os Testes Manualmente

Este guia mostra como executar cada tipo de teste do módulo de Login.

## 📋 Tipos de Testes

1. **Testes Unitários do BLoC** - Testam a lógica de negócio
2. **Testes de Integração** - Testam a UI completa e interações
3. **Testes de Widget** - Testam componentes isolados (em desenvolvimento)

---

## 1️⃣ Testes Unitários do BLoC

Testam a lógica de negócio, estados e eventos do `LoginBloc`.

### Rodar todos os testes do BLoC:
```bash
cd app
flutter test test/features/login/bloc/
```

### Rodar um arquivo específico:
```bash
# Testes principais do login
flutter test test/features/login/bloc/login_bloc_test.dart

# Testes de refresh token
flutter test test/features/login/bloc/login_bloc_refresh_test.dart
```

### Rodar um teste específico:
```bash
# Por nome do teste
flutter test test/features/login/bloc/login_bloc_test.dart --plain-name "Login com credenciais válidas"
```

### Ver saída detalhada:
```bash
flutter test test/features/login/bloc/login_bloc_test.dart --reporter expanded
```

---

## 2️⃣ Testes de Integração

Testam a UI completa, navegação, interações e **validam alterações visuais**.

### ⚠️ Pré-requisitos:
- Backend rodando em `http://localhost:8080`
- Banco de dados com migrations executadas
- Usuário de teste criado (ou criar durante os testes)

### Rodar testes de integração:
```bash
cd app
flutter test integration_test/login_visual_test.dart
```

### Rodar um teste específico:
```bash
# Com --no-pub para acelerar (não reinstala dependências)
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1 - Login with valid credentials"
```

### Ver saída detalhada:
```bash
flutter test integration_test/login_visual_test.dart --reporter expanded
```

### Rodar em um dispositivo/emulador específico:
```bash
# Listar dispositivos disponíveis
flutter devices

# Rodar em um dispositivo específico
flutter test integration_test/login_visual_test.dart -d <device-id>
```

---

## 3️⃣ Testes de Widget

Testam componentes isolados da UI (atualmente com problemas de setup).

### ⚠️ Nota:
Os testes de widget estão em desenvolvimento e podem ter problemas de setup devido às dependências do `DependencyContainer`.

### Tentar rodar:
```bash
cd app
flutter test test/features/login/widgets/login_form_widget_test.dart
```

---

## 🎯 Comandos Úteis

### Rodar TODOS os testes de login:
```bash
cd app
flutter test test/features/login/
```

### Rodar TODOS os testes do projeto:
```bash
cd app
flutter test
```

### Rodar com cobertura:
```bash
cd app
flutter test --coverage
```

### Ver relatório de cobertura:
```bash
cd app
# Após rodar com --coverage, o arquivo será gerado em:
# coverage/lcov.info
# 
# Para visualizar, instale lcov e gere HTML:
# brew install lcov
# genhtml coverage/lcov.info -o coverage/html
# open coverage/html/index.html
```

### Rodar apenas testes que falharam:
```bash
flutter test --reporter expanded
```

### Rodar testes em modo verbose:
```bash
flutter test --verbose
```

---

## 📊 Resumo Rápido

| Tipo de Teste | Comando | Valida Visual? |
|---------------|---------|---------------|
| **Unitário (BLoC)** | `flutter test test/features/login/bloc/` | ❌ Não |
| **Integração** | `flutter test integration_test/login_visual_test.dart` | ✅ Sim |
| **Widget** | `flutter test test/features/login/widgets/` | ✅ Sim (em dev) |

---

## 🔍 Debugging

### Ver logs detalhados:
```bash
flutter test --verbose test/features/login/bloc/login_bloc_test.dart
```

### Rodar um teste específico e parar no primeiro erro:
```bash
flutter test test/features/login/bloc/login_bloc_test.dart --stop-on-first-failure
```

### ⚡ Acelerar Testes de Integração

**Importante**: O Flutter não tem uma flag `--keep-app-running` nativa, mas você pode otimizar:

#### Opção 1: Usar `--no-pub` (evita reinstalar dependências)
```bash
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1 - Login with valid credentials"
```

#### Opção 2: Rodar múltiplos testes de uma vez (app inicia uma vez)
```bash
# Roda todos os testes do arquivo (mais rápido que rodar um por vez)
flutter test integration_test/login_visual_test.dart --no-pub
```

#### Opção 3: Usar `flutter drive` (melhor para desenvolvimento iterativo)
```bash
# Primeiro, inicie o app manualmente ou use um script
# Depois, rode os testes com driver customizado
flutter drive \
  --driver=test_driver/integration_test_driver.dart \
  --target=integration_test/login_visual_test.dart \
  --device-id=<device-id>
```

#### Opção 4: Hot Reload durante desenvolvimento
```bash
# 1. Inicie o app em modo debug
flutter run

# 2. Em outro terminal, rode os testes
flutter test integration_test/login_visual_test.dart --no-pub
```

---

## 📝 Exemplos Práticos

### Exemplo 1: Validar que o login funciona após mudança no código
```bash
# 1. Rodar testes unitários (rápido)
flutter test test/features/login/bloc/login_bloc_test.dart

# 2. Se passou, rodar testes de integração (mais lento, mas valida visual)
flutter test integration_test/login_visual_test.dart
```

### Exemplo 2: Testar apenas um cenário específico
```bash
# Teste unitário específico
flutter test test/features/login/bloc/login_bloc_test.dart --plain-name "Login com credenciais inválidas"

# Teste de integração específico
flutter test integration_test/login_visual_test.dart --plain-name "Login with invalid credentials"
```

### Exemplo 3: Verificar cobertura de testes
```bash
flutter test --coverage test/features/login/
# Ver relatório em coverage/lcov.info
```

---

## 🚨 Troubleshooting

### Erro: "No devices found"
```bash
# Para testes de integração, você precisa de um dispositivo/emulador
flutter devices
# Se não houver, inicie um emulador ou conecte um dispositivo físico
```

### Erro: "Backend não está rodando"
- Certifique-se de que o backend está em `http://localhost:8080`
- Verifique se o banco de dados está configurado corretamente

### Erro: "DependencyContainer não inicializado"
- Os testes de widget podem ter esse problema
- Use os testes de integração que já têm o setup completo

---

## 📚 Referências

- [Flutter Testing Docs](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Widget Testing](https://docs.flutter.dev/testing/widget-tests)


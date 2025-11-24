# ⚡ Comandos Rápidos para Testes de Integração

## 🚀 Acelerar Execução dos Testes

### Comando Básico (com otimização)
```bash
cd app
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1 - Login with valid credentials"
```

**O que `--no-pub` faz:**
- ✅ Evita reinstalar dependências a cada execução
- ✅ Acelera significativamente os testes
- ⚠️ Use apenas se as dependências não mudaram

### Rodar Teste Específico (mais rápido)
```bash
# Teste único - app inicia e fecha rapidamente
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1 - Login with valid credentials"
```

### Rodar Todos os Testes (otimizado)
```bash
# App inicia UMA vez para todos os testes (mais eficiente)
flutter test integration_test/login_visual_test.dart --no-pub
```

## 🔄 Estratégias para Desenvolvimento Iterativo

### Estratégia 1: Teste Único Rápido
```bash
# Para testar uma mudança específica rapidamente
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1 - Login with valid credentials"
```

### Estratégia 2: Hot Reload + Testes
```bash
# Terminal 1: Mantém o app rodando
flutter run

# Terminal 2: Roda testes (app já está compilado)
flutter test integration_test/login_visual_test.dart --no-pub
```

### Estratégia 3: Agrupar Testes Relacionados
```bash
# Roda todos os testes de uma seção de uma vez
flutter test integration_test/login_visual_test.dart --no-pub
```

## 📊 Comparação de Velocidade

| Método | Tempo Aproximado | Quando Usar |
|--------|------------------|-------------|
| `flutter test` (sem --no-pub) | ~40-60s | Primeira vez, após mudar dependências |
| `flutter test --no-pub` | ~20-30s | Desenvolvimento iterativo |
| `flutter test --no-pub` (todos) | ~2-3min | Validação completa |
| `flutter test --no-pub` (um teste) | ~15-25s | Teste rápido de uma funcionalidade |

## 🎯 Dicas de Performance

1. **Use `--no-pub` sempre que possível**
   ```bash
   flutter test integration_test/login_visual_test.dart --no-pub
   ```

2. **Rode testes específicos durante desenvolvimento**
   ```bash
   flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1"
   ```

3. **Rode todos os testes antes de commitar**
   ```bash
   flutter test integration_test/login_visual_test.dart --no-pub
   ```

4. **Use `--reporter expanded` para ver progresso**
   ```bash
   flutter test integration_test/login_visual_test.dart --no-pub --reporter expanded
   ```

## ⚠️ Limitações

- ❌ Não há flag `--keep-app-running` nativa no Flutter
- ✅ Mas `--no-pub` acelera significativamente
- ✅ Agrupar testes em um arquivo reduz tempo total
- ✅ Testes específicos são mais rápidos que rodar todos

## 🔧 Comandos Úteis Adicionais

### Ver apenas o teste que está rodando
```bash
flutter test integration_test/login_visual_test.dart --no-pub --plain-name "1.1.1" --reporter expanded
```

### Parar no primeiro erro
```bash
flutter test integration_test/login_visual_test.dart --no-pub --stop-on-first-failure
```

### Modo verbose (ver todos os logs)
```bash
flutter test integration_test/login_visual_test.dart --no-pub --verbose
```


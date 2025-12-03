# ⚡ Início Rápido - Testes

## 🚀 Comandos Essenciais

### Executar Todos os Testes

```bash
./scripts/run-all-tests.sh
```

### Executar Apenas Backend

```bash
./deploy/run-backend-tests.sh
```

### Executar Apenas Frontend

```bash
./deploy/run-frontend-tests.sh
```

### Gerar Relatórios de Cobertura

```bash
./scripts/generate-coverage-report.sh
```

---

## 📖 Documentação Completa

- **[Como Rodar Testes](./COMO_RODAR_TESTES.md)** - Guia completo e detalhado
- **[Guia de Testes](./TESTING.md)** - Estrutura e conceitos

---

## ✅ Checklist Rápido

Antes de fazer push:

```bash
# 1. Executar todos os testes
./scripts/run-all-tests.sh

# 2. Verificar cobertura
./scripts/generate-coverage-report.sh

# 3. Se tudo passou, fazer push
git push
```

---

## 🆘 Problemas Comuns

**Testes falhando?**
```bash
# Limpar e reinstalar dependências
cd server && dart pub get
cd app && flutter pub get
```

**Cobertura abaixo de 80%?**
```bash
# Ver relatório detalhado
./scripts/generate-coverage-report.sh
open coverage-reports/backend/html/index.html
```

**Pular testes temporariamente (não recomendado)?**
```bash
SKIP_TESTS=1 git push
```


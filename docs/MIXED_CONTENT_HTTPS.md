# 🔒 Problema de Mixed Content (HTTPS/HTTP)

## 🐛 Problema Identificado

Quando a aplicação Flutter Web está em HTTPS (`https://app.terafy.app.br/`), mas tenta fazer requisições HTTP para a API (`http://api.terafy.app.br`), os navegadores bloqueiam essas requisições por segurança (Mixed Content).

### Erro típico:
```
Mixed Content: The page at 'https://app.terafy.app.br/' was loaded over HTTPS, 
but requested an insecure XMLHttpRequest endpoint 'http://api.terafy.app.br/auth/login'. 
This request has been blocked; the content must be served over HTTPS.
```

## ✅ Solução Implementada

O código foi ajustado para:

1. **Detectar automaticamente o protocolo** da página atual em produção web
2. **Usar HTTPS sempre** quando estiver em domínios de produção (`*.terafy.app.br`)
3. **Manter HTTP apenas** para desenvolvimento local (`localhost`)

### Arquivo modificado:
- `app/lib/core/dependencies/dependency_container.dart`

## 🔧 Como Funciona Agora

### Em Produção Web:
- Se a página está em `https://app.terafy.app.br` → API usa `https://api.terafy.app.br`
- Detecção automática baseada no domínio

### Em Desenvolvimento Local:
- Se a página está em `http://localhost:8080` → API usa `http://localhost:8080`

### Em Mobile (Android/iOS):
- Sempre usa `https://api.terafy.app.br` em produção

## 📋 Próximos Passos

### 1. Fazer Novo Build

O build atual em produção foi feito com código antigo. É necessário fazer um novo build:

```bash
cd app

# Limpar builds anteriores
flutter clean

# Build para produção
flutter build web --release
```

### 2. Limpar Cache do Navegador

O navegador pode ter cacheado o código JavaScript antigo:

1. Abra `https://app.terafy.app.br` no navegador
2. Pressione `Ctrl + Shift + R` (Windows/Linux) ou `Cmd + Shift + R` (Mac) para hard refresh
3. Ou abra o DevTools (F12) → Network → Marque "Disable cache"

### 3. Fazer Deploy

Copie os novos arquivos para o servidor:

```bash
# Copiar build para VM
gcloud compute scp --recurse app/build/web/* terafy-freetier-vm:~/terafy-deploy/web/app/
```

### 4. Verificar

Após o deploy, verifique:

1. Abra `https://app.terafy.app.br` no navegador
2. Abra o DevTools (F12) → Console
3. Tente fazer login
4. Verifique se as requisições estão indo para `https://api.terafy.app.br` (não `http://`)

## 🔍 Como Verificar se Está Funcionando

### No Console do Navegador:

Antes (com erro):
```
Mixed Content: The page at 'https://app.terafy.app.br/' was loaded over HTTPS, 
but requested an insecure XMLHttpRequest endpoint 'http://api.terafy.app.br/auth/login'.
```

Depois (corrigido):
- As requisições devem aparecer no Network tab como:
  - `https://api.terafy.app.br/auth/login` ✅
  - Não deve mais aparecer `http://api.terafy.app.br` ❌

### No Network Tab (F12 → Network):

1. Filtre por "XHR" ou "Fetch"
2. Tente fazer login
3. Verifique a requisição para `/auth/login`
4. A URL deve ser `https://api.terafy.app.br/auth/login`
5. O status deve ser 200 (ou o código de erro apropriado, mas não "blocked")

## 🚨 Importante

- **Nunca use HTTP em produção** quando a página está em HTTPS
- O código agora detecta automaticamente e sempre usa HTTPS em produção
- Para desenvolvimento local, ainda pode usar HTTP (`localhost`)

## 📝 Notas Técnicas

- A detecção é feita através de `Uri.base.scheme` no Flutter Web
- Se o host contém `terafy.app.br`, sempre usa HTTPS
- Em caso de erro na detecção, usa HTTPS como padrão seguro
- O código está preparado para funcionar tanto em HTTP quanto HTTPS localmente


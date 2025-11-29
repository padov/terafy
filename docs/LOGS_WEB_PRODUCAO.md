# 📋 Como Ver Logs da Flutter Web em Produção

## 🎯 Onde os Logs Aparecem

A Flutter Web roda **no navegador do cliente**, então os logs aparecem no **Console do Navegador**, não no servidor!

## 🔍 Como Ver os Logs

### 1. **Abrir o Console do Navegador**

#### Chrome/Edge/Brave:
- **Windows/Linux**: `F12` ou `Ctrl + Shift + I` ou `Ctrl + Shift + J`
- **Mac**: `Cmd + Option + I` ou `Cmd + Option + J`
- Ou: Menu → Mais ferramentas → Ferramentas do desenvolvedor

#### Firefox:
- **Windows/Linux**: `F12` ou `Ctrl + Shift + I`
- **Mac**: `Cmd + Option + I`

#### Safari:
- **Mac**: `Cmd + Option + C`
- Ou: Menu Desenvolvedor → Mostrar Console Web
- ⚠️ **Nota**: Precisar habilitar o menu Desenvolvedor antes:
  - Preferências → Avançado → Marcar "Mostrar menu Desenvolvedor na barra de menus"

### 2. **Acessar a Aba Console**

Depois de abrir as ferramentas do desenvolvedor, clique na aba **"Console"**.

### 3. **Filtrar Logs**

No console, você verá:
- ✅ **Logs normais** (branco/cinza)
- ⚠️ **Warnings** (amarelo)
- ❌ **Erros** (vermelho)

Para filtrar apenas erros:
- No Chrome: Clique no ícone de filtro e marque apenas "Errors"
- Ou digite `error` na barra de pesquisa do console

## ⚠️ Erros que Podem Ser Ignorados

### Erro de Service Worker (NÃO é um problema!)

Se você ver este erro no console:
```
Exception while loading service worker: Error: Service Worker API unavailable.
The current context is NOT secure.
```

**Pode ignorar!** Isso acontece porque:
- Service Workers só funcionam em HTTPS ou localhost
- Em HTTP (sem SSL), esse erro é **normal** e **esperado**
- **NÃO afeta a funcionalidade** da aplicação
- É apenas um aviso do navegador

**Solução**: Se quiser eliminar esse aviso, configure HTTPS para produção.

## 🔧 Logs que Serão Capturados

Agora o app captura automaticamente:

1. **Erros do Flutter Framework** (`FlutterError.onError`)
   - Erros de build, renderização, etc.
   - Aparecem com prefixo: `🚨 ERRO DO FLUTTER WEB`

2. **Erros não capturados** (`PlatformDispatcher.onError`)
   - Exceções que não foram tratadas
   - Aparecem com prefixo: `🚨 ERRO NÃO CAPTURADO NO FLUTTER WEB`

3. **Logs do AppLogger**
   - Todos os logs do sistema (se `isDebugMode = true`)
   - Erros, warnings, info, etc.

## 📸 Como Capturar o Erro

### Opção 1: Screenshot do Console
1. Reproduza o erro na aplicação
2. Abra o console (F12)
3. Veja os erros em vermelho
4. Tire um screenshot ou copie o texto

### Opção 2: Copiar Texto do Console
1. Clique com botão direito no erro no console
2. Escolha "Copy" ou "Copiar"
3. Cole em um arquivo de texto

### Opção 3: Salvar Logs do Console
1. Abra o console
2. Clique com botão direito na área de logs
3. Escolha "Save as..." (salvar como)
4. Salve em um arquivo `.txt` ou `.log`

## 🐛 Para Depurar em Produção

### ⚠️ IMPORTANTE: Diferenciar Erros

No console, você verá **dois tipos de erros**:

1. **Erro do Service Worker** (PODE IGNORAR):
   ```
   Service Worker API unavailable
   The current context is NOT secure
   ```
   - ⚠️ **IGNORE ESTE** - é apenas um aviso

2. **Erro de Null Check** (PROBLEMA REAL):
   ```
   Null check operator used on a null value
   ```
   - ❌ **ESTE É O PROBLEMA** que precisa ser corrigido
   - Procure por este erro específico no console

### 1. **Verificar Erros de Rede**

No console do navegador, vá para a aba **"Network"** (Rede):
- Veja todas as requisições HTTP
- Verifique se alguma está falhando (status 4xx ou 5xx)
- Clique em uma requisição para ver detalhes (headers, response, etc.)
- **Procure especialmente** por requisições de login (`/auth/login`) que falharem

### 2. **Verificar Erros JavaScript**

Na aba **"Console"**:
- Todos os erros JavaScript aparecem em vermelho
- Clique no erro para ver o stack trace completo
- Veja em qual arquivo e linha o erro ocorreu

### 3. **Modo Debug do Flutter**

Se você quiser ver logs mais detalhados em produção, adicione `?debug=true` na URL:
```
https://app.terafy.app.br?debug=true
```

E configure no código para ativar debug quando o parâmetro estiver presente.

## 📝 Exemplo de Log de Erro

Quando ocorre um erro, você verá algo assim no console:

```
═══════════════════════════════════════════════════════════════
🚨 ERRO DO FLUTTER WEB
═══════════════════════════════════════════════════════════════
Exception: Null check operator used on a null value
Library: package:flutter/src/widgets/framework.dart
═══════════════════════════════════════════════════════════════
Stack trace:
#0      RefreshTokenRepository._extractTokenId
        package:server/lib/features/auth/refresh_token.repository.dart:78
#1      RefreshTokenRepository.createRefreshToken
        package:server/lib/features/auth/refresh_token.repository.dart:43
...
```

## 🚀 Próximos Passos

Se você encontrar o erro "Null check operator used on a null value":

1. **Copie o erro completo** do console (incluindo stack trace)
2. **Verifique qual linha** está causando o problema
3. **Verifique os dados** sendo passados (pode usar `console.log()` temporariamente)
4. **Teste a correção** localmente antes de fazer deploy

## 🔗 Links Úteis

- [Chrome DevTools - Console](https://developer.chrome.com/docs/devtools/console/)
- [Firefox DevTools - Console](https://firefox-source-docs.mozilla.org/devtools-user/web_console/)
- [Flutter Web Debugging](https://docs.flutter.dev/deployment/web)

## 📌 Nota Importante

⚠️ **Lembre-se**: Os logs aparecem no navegador do **usuário final**, não no servidor!

Para capturar logs automaticamente do lado do servidor, seria necessário:
1. Criar um endpoint `/api/logs` no servidor
2. Enviar erros do cliente para esse endpoint
3. Salvar em arquivo de log ou banco de dados

Isso pode ser implementado no futuro se necessário.


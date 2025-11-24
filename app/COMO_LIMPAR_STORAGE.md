# 🗑️ Como Limpar o Storage do App

Este guia mostra todas as formas de limpar o storage (dados salvos) do app Terafy.

## 📱 Métodos Disponíveis

### 1. **Usando o Makefile (Recomendado)**

No diretório raiz do projeto:

```bash
make clear-storage
```

Este comando limpa todos os dados do app Android, incluindo:
- Tokens de autenticação
- Dados do usuário
- Preferências
- Cache

### 2. **Usando o Script Shell**

No diretório `app/`:

```bash
cd app
./clear_storage.sh
```

Ou:

```bash
cd app
bash clear_storage.sh
```

**Nota:** Se o script não tiver permissão de execução:
```bash
chmod +x clear_storage.sh
./clear_storage.sh
```

### 3. **Comando ADB Direto (Android)**

Se você tem um dispositivo/emulador Android conectado:

```bash
adb shell pm clear com.example.terafy
```

### 4. **Para iOS (Simulador)**

No simulador iOS, você pode:

**Opção A: Resetar o simulador**
```bash
xcrun simctl erase all
```

**Opção B: Deletar apenas o app do simulador**
1. Abra o Simulador
2. Mantenha pressionado o ícone do app
3. Selecione "Delete App"

**Opção C: Via código (durante desenvolvimento)**
O código de teste já limpa o storage automaticamente usando:
```dart
await IntegrationTestHelpers.clearAppData();
```

### 5. **Limpar Storage Programaticamente (Dart)**

Se você quiser limpar o storage dentro do código Dart:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.deleteAll(); // Limpa tudo
```

Ou usando o `DependencyContainer`:

```dart
await DependencyContainer().secureStorageService.clearAll();
```

## 🔍 Verificar se o Storage foi Limpo

### Android (via ADB)

```bash
# Ver dados do app
adb shell dumpsys package com.example.terafy | grep -A 5 "dataDir"

# Ver se há tokens salvos (requer root)
adb shell run-as com.example.terafy ls -la /data/data/com.example.terafy/
```

### Durante Testes

Os testes de integração já verificam automaticamente se o storage está limpo. Se você executar:

```bash
flutter test integration_test/login_visual_test.dart --no-pub
```

O `setUp` de cada teste chama `clearAppData()` automaticamente.

## ⚠️ Problemas Comuns

### "adb: command not found"
- Instale o Android SDK Platform Tools
- Adicione ao PATH: `export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools`

### "Error: no devices/emulators found"
- Certifique-se de que um dispositivo/emulador está conectado
- Verifique com: `adb devices`

### "Package com.example.terafy not found"
- O app precisa estar instalado no dispositivo
- Instale com: `flutter install` ou `flutter run`

### Script não executa
```bash
chmod +x clear_storage.sh
./clear_storage.sh
```

## 🎯 Quando Usar Cada Método

| Método | Quando Usar |
|--------|-------------|
| `make clear-storage` | Desenvolvimento geral, antes de rodar testes |
| `./clear_storage.sh` | Se você está no diretório `app/` |
| `adb shell pm clear` | Controle direto, debugging avançado |
| Resetar simulador iOS | Quando precisa limpar tudo do simulador |
| `clearAppData()` no código | Durante testes automatizados |

## 📝 Notas Importantes

1. **Limpar o storage remove TODOS os dados do app**, incluindo:
   - Tokens de autenticação
   - Preferências do usuário
   - Cache
   - Dados locais

2. **Os testes de integração limpam automaticamente** o storage antes de cada teste (veja `setUp` em `login_visual_test.dart`).

3. **Para desenvolvimento manual**, use `make clear-storage` antes de testar fluxos de login/logout.

4. **O package name é**: `com.example.terafy` (definido em `android/app/build.gradle.kts`)

---

💡 **Dica:** Se você está tendo problemas com tokens persistidos durante testes, sempre execute `make clear-storage` antes de rodar os testes manualmente.


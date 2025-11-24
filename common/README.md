# Logger

Pacote de logging genérico compartilhado entre frontend (Flutter) e backend (Dart puro).

## Características

- ✅ Funciona tanto no Flutter quanto no Dart puro
- ✅ Logs coloridos usando ANSI styles
- ✅ Diferentes níveis de log (debug, info, warning, error)
- ✅ Suporte a stack traces
- ✅ Configurável para modo debug/produção

## Uso

### Configuração Inicial

No **Flutter** (app):
```dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configura o logger usando kDebugMode
  AppLogger.config(isDebugMode: kDebugMode);
  
  // ... resto do código
}
```

No **Backend** (server):
```dart
import 'package:logger/logger.dart';

void main() async {
  // Configura o logger
  // Em produção, pode usar variável de ambiente:
  // const bool.fromEnvironment('DEBUG', defaultValue: false)
  AppLogger.config(isDebugMode: true);
  
  // ... resto do código
}
```

### Métodos Disponíveis

```dart
// Log de debug (nível mais baixo)
AppLogger.debug('Mensagem de debug');

// Log de informação
AppLogger.info('Informação importante');

// Log de aviso
AppLogger.warning('Atenção!');

// Log de erro (com stack trace opcional)
AppLogger.error(exception, stackTrace);

// Log de variável
AppLogger.variable('nomeDaVariavel', valor);

// Log de função (detecta automaticamente ou pode passar nome)
AppLogger.func(); // Detecta automaticamente
AppLogger.func(name: 'minhaFuncao'); // Passa nome manualmente

// Log customizado com nível específico
AppLogger.log(Level.INFO, 'Mensagem customizada');
```

## Níveis de Log

- `Level.FINEST` / `Level.FINER` / `Level.FINE` → `AppLogger.debug()` (verde)
- `Level.CONFIG` → `AppLogger.config()` (cyan)
- `Level.INFO` → `AppLogger.info()` (azul)
- `Level.WARNING` → `AppLogger.warning()` (amarelo)
- `Level.SEVERE` → `AppLogger.error()` (vermelho)

## Exemplo de Saída

```
[2024-01-15T10:30:45.123Z][INFO   ] Mensagem de informação
[2024-01-15T10:30:45.456Z][WARNING] Atenção!
[2024-01-15T10:30:45.789Z][SEVERE ] Erro: Exception: Algo deu errado
```

## Dependências

- `logging`: ^1.2.0
- `ansi_styles`: ^1.1.1
- `stack_trace`: ^1.11.1


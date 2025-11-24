import 'package:logging/logging.dart';
import 'package:ansi_styles/ansi_styles.dart';
import 'package:stack_trace/stack_trace.dart';
import 'dart:developer' as developer;

class AppLogger {
  static final Logger _logger = Logger('AppLogger');
  static bool _isDebugMode = false;
  static bool _isInitialized = false;

  /// Configura o logger
  /// [isDebugMode] - Se true, habilita logs detalhados. Se false, desabilita todos os logs.
  /// Por padrão, tenta detectar automaticamente se está em modo debug.
  static void config({bool? isDebugMode}) {
    if (_isInitialized) {
      return; // Evita reconfiguração
    }

    // Tenta detectar modo debug automaticamente se não foi especificado
    if (isDebugMode == null) {
      // Verifica variável de ambiente ou assume debug em desenvolvimento
      _isDebugMode = const bool.fromEnvironment('DEBUG', defaultValue: true);
    } else {
      _isDebugMode = isDebugMode;
    }

    if (!_isDebugMode) {
      Logger.root.level = Level.OFF;
      _isInitialized = true;
      return;
    }

    Logger.root.level = Level.ALL;

    Logger.root.onRecord.listen((LogRecord record) {
      final time = record.time.toIso8601String();
      final level = record.level.name.padRight(7);
      final message = record.message;
      final error = record.error != null ? 'Error: ${record.error}' : '';
      final stackTrace = record.stackTrace != null
          ? 'StackTrace: ${record.stackTrace}'
          : '';

      String coloredMessage;
      switch (record.level) {
        case Level.SEVERE:
          coloredMessage = AnsiStyles.red('$message $error $stackTrace');
          break;
        case Level.WARNING:
          coloredMessage = AnsiStyles.yellow('$message $error $stackTrace');
          break;
        case Level.INFO:
          coloredMessage = AnsiStyles.blue('$message $error $stackTrace');
          break;
        case Level.CONFIG:
          coloredMessage = AnsiStyles.cyan('$message $error $stackTrace');
          break;
        case Level.FINE:
        case Level.FINER:
        case Level.FINEST:
          coloredMessage = AnsiStyles.green('$message $error $stackTrace');
          break;
        default:
          coloredMessage = AnsiStyles.reset('$message $error $stackTrace');
      }

      print('[$time][$level] $coloredMessage');

      // developer.log só funciona em contextos que suportam (Flutter, Dart DevTools)
      try {
        developer.log('[$time][$level] $coloredMessage');
      } catch (e) {
        // Ignora se não estiver disponível (ex: backend puro)
      }
    });

    _isInitialized = true;
  }

  static void log(Level level, String message) {
    _logger.log(level, message);
  }

  static void info(String message) {
    _logger.info(message);
  }

  static void debug(String message) {
    _logger.finest(message);
  }

  static void variable(String name, Object value) {
    _logger.finest('$name > $value');
  }

  static void warning(String message) {
    _logger.warning(message);
  }

  /// Log de rastreamento de função (function tracing)
  ///
  /// Útil para debug e rastreamento do fluxo da aplicação.
  /// Em produção, pode ser desabilitado através de [isDebugMode].
  ///
  /// [name] - Nome customizado da função. Se null, tenta detectar automaticamente.
  ///
  /// Exemplo:
  /// ```dart
  /// void minhaFuncao() {
  ///   AppLogger.func(); // Detecta automaticamente: "minhaFuncao"
  ///   // ou
  ///   AppLogger.func(name: 'minhaFuncao'); // Nome explícito
  /// }
  /// ```
  static void func({String? name}) {
    // Se não está em modo debug, não faz nada (evita overhead)
    if (!_isDebugMode) {
      return;
    }

    final function = _resolveFunctionName(name: name, stackLevel: 1);

    // Usa Level.FINE (debug) ao invés de WARNING para não confundir
    // WARNING geralmente indica problemas, não rastreamento
    _logger.fine('→ $function');
  }

  static String _resolveFunctionName({String? name, int stackLevel = 0}) {
    if (name != null && name.isNotEmpty) {
      return name;
    }

    try {
      final trace = Trace.current(stackLevel + 1);
      final frame = trace.frames.first;
      final parts = frame.toString().split(' ');
      if (parts.length > 3) {
        return parts[3];
      }
      final extracted = frame.toString();
      if (extracted.isNotEmpty) {
        return extracted;
      }
    } catch (_) {
      // Ignorado, cai no retorno padrão
    }

    return 'Função não identificada';
  }

  static void error(Object e, [StackTrace? stackTrace]) {
    // Imprime stack trace se disponível
    var functionName = 'error';

    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
      functionName = _resolveFunctionName(name: 'error', stackLevel: 1);
    }
    _logger.severe('[$functionName] ${e.toString()}', stackTrace);
  }

  /// Verifica se o logger está em modo debug
  static bool get isDebugMode => _isDebugMode;
}

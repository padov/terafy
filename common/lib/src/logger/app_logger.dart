import 'package:logging/logging.dart';
import 'package:ansi_styles/ansi_styles.dart';
import 'package:stack_trace/stack_trace.dart';
import 'dart:developer' as developer;
import 'dart:io';

class AppLogger {
  static final Logger _logger = Logger('AppLogger');
  static bool _isDebugMode = false;
  static bool _isInitialized = false;
  static _FileLogHandler? _fileHandler;

  /// Configura o logger
  /// [isDebugMode] - Se true, habilita logs detalhados. Se false, desabilita todos os logs.
  /// [logToFile] - Se true, grava logs em arquivo (apenas para servidor).
  /// [logDirectory] - Diretório onde os logs serão salvos (padrão: './log').
  /// [logLevel] - Nível de log a ser usado (padrão: Level.ALL).
  /// [maxFileSizeMB] - Tamanho máximo do arquivo de log em MB antes da rotação (padrão: 20).
  /// [retentionDays] - Dias de retenção de logs antes da limpeza automática (padrão: 30).
  /// [compressRotated] - Se true, comprime logs rotacionados com gzip (padrão: true).
  /// Por padrão, tenta detectar automaticamente se está em modo debug.
  static void config({
    bool? isDebugMode,
    bool logToFile = false,
    String logDirectory = './log',
    Level? logLevel,
    int maxFileSizeMB = 20,
    int retentionDays = 30,
    bool compressRotated = true,
  }) {
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

    // Configura o nível de log
    Logger.root.level = logLevel ?? Level.ALL;

    // Inicializa file handler se necessário
    if (logToFile) {
      try {
        _fileHandler = _FileLogHandler(
          directory: logDirectory,
          maxFileSizeMB: maxFileSizeMB,
          retentionDays: retentionDays,
          compressRotated: compressRotated,
        );
      } catch (e) {
        print('⚠️  Erro ao inicializar log em arquivo: $e');
        print('   Continuando apenas com log no console...');
      }
    }

    Logger.root.onRecord.listen((LogRecord record) {
      final time = record.time.toIso8601String();
      final level = record.level.name.padRight(7);
      final message = record.message;
      final error = record.error != null ? 'Error: ${record.error}' : '';
      final stackTrace = record.stackTrace != null ? 'StackTrace: ${record.stackTrace}' : '';

      // Mensagem sem cores para arquivo
      final plainMessage = '$message $error $stackTrace'.trim();
      final logLine = '[$time][$level] $plainMessage';

      // Grava em arquivo se habilitado
      _fileHandler?.write(logLine);

      // Console com cores
      String coloredMessage;
      switch (record.level) {
        case Level.SEVERE:
          coloredMessage = AnsiStyles.red(plainMessage);
          break;
        case Level.WARNING:
          coloredMessage = AnsiStyles.yellow(plainMessage);
          break;
        case Level.INFO:
          coloredMessage = AnsiStyles.blue(plainMessage);
          break;
        case Level.CONFIG:
          coloredMessage = AnsiStyles.cyan(plainMessage);
          break;
        case Level.FINE:
        case Level.FINER:
        case Level.FINEST:
          coloredMessage = AnsiStyles.green(plainMessage);
          break;
        default:
          coloredMessage = AnsiStyles.reset(plainMessage);
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

  /// Fecha o arquivo de log (útil para testes e shutdown graceful)
  static void close() {
    _fileHandler?.close();
    _fileHandler = null;
    _isInitialized = false;
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

/// Handler interno para gerenciar logs em arquivo com rotação automática
class _FileLogHandler {
  final String directory;
  final int maxFileSizeMB;
  final int retentionDays;
  final bool compressRotated;
  IOSink? _sink;
  String? _currentFilePath;
  String? _currentDate;

  _FileLogHandler({
    required this.directory,
    required this.maxFileSizeMB,
    required this.retentionDays,
    required this.compressRotated,
  }) {
    _ensureDirectoryExists();
    _cleanupOldLogs();
    _openLogFile();
  }

  void _ensureDirectoryExists() {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Comprime um arquivo de log usando gzip
  void _compressFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      // Lê o conteúdo do arquivo
      final bytes = file.readAsBytesSync();

      // Comprime usando gzip
      final compressed = gzip.encode(bytes);

      // Salva arquivo comprimido
      final compressedFile = File('$filePath.gz');
      compressedFile.writeAsBytesSync(compressed);

      // Remove arquivo original
      file.deleteSync();

      print('📦 Log comprimido: ${compressedFile.path}');
    } catch (e) {
      print('⚠️  Erro ao comprimir log $filePath: $e');
    }
  }

  /// Limpa logs mais antigos que o período de retenção
  void _cleanupOldLogs() {
    try {
      final dir = Directory(directory);
      if (!dir.existsSync()) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: retentionDays));

      // Lista todos os arquivos de log
      final files = dir.listSync().whereType<File>().where((file) {
        final name = file.path.split('/').last;
        return name.startsWith('app_') && (name.endsWith('.log') || name.endsWith('.log.gz'));
      });

      int deletedCount = 0;
      for (final file in files) {
        try {
          // Extrai a data do nome do arquivo (app_YYYY-MM-DD.log ou app_YYYY-MM-DD_N.log.gz)
          final name = file.path.split('/').last;
          final dateMatch = RegExp(r'app_(\d{4}-\d{2}-\d{2})').firstMatch(name);

          if (dateMatch != null) {
            final dateStr = dateMatch.group(1)!;
            final fileDateParts = dateStr.split('-');
            final fileDate = DateTime(
              int.parse(fileDateParts[0]),
              int.parse(fileDateParts[1]),
              int.parse(fileDateParts[2]),
            );

            // Deleta se for mais antigo que o período de retenção
            if (fileDate.isBefore(cutoffDate)) {
              file.deleteSync();
              deletedCount++;
            }
          }
        } catch (e) {
          print('⚠️  Erro ao processar arquivo ${file.path}: $e');
        }
      }

      if (deletedCount > 0) {
        print('🗑️  $deletedCount log(s) antigo(s) removido(s)');
      }
    } catch (e) {
      print('⚠️  Erro ao limpar logs antigos: $e');
    }
  }

  void _openLogFile() {
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    // Se mudou o dia, comprime arquivo antigo e cria novo
    if (_currentDate != dateStr) {
      final oldFilePath = _currentFilePath;
      _closeCurrentFile();

      // Comprime arquivo do dia anterior se habilitado
      if (compressRotated && oldFilePath != null && File(oldFilePath).existsSync()) {
        _compressFile(oldFilePath);
      }

      _currentDate = dateStr;
      _currentFilePath = _getLogFilePath(dateStr, 0);
      _cleanupOldLogs(); // Limpa logs antigos ao mudar de dia
    }

    // Verifica se precisa rotacionar por tamanho
    if (_currentFilePath != null && File(_currentFilePath!).existsSync()) {
      final fileSize = File(_currentFilePath!).lengthSync();
      final maxSizeBytes = maxFileSizeMB * 1024 * 1024;

      if (fileSize >= maxSizeBytes) {
        _rotateBySize(dateStr);
      }
    }

    // Abre o arquivo em modo append
    if (_sink == null) {
      _sink = File(_currentFilePath!).openWrite(mode: FileMode.append);
    }
  }

  void _rotateBySize(String dateStr) {
    final oldFilePath = _currentFilePath;
    _closeCurrentFile();

    // Comprime arquivo rotacionado se habilitado
    if (compressRotated && oldFilePath != null && File(oldFilePath).existsSync()) {
      _compressFile(oldFilePath);
    }

    // Encontra o próximo número disponível
    int counter = 1;
    while (File(_getLogFilePath(dateStr, counter)).existsSync() ||
        File('${_getLogFilePath(dateStr, counter)}.gz').existsSync()) {
      counter++;
    }

    _currentFilePath = _getLogFilePath(dateStr, counter);
  }

  String _getLogFilePath(String dateStr, int counter) {
    if (counter == 0) {
      return '$directory/app_$dateStr.log';
    }
    return '$directory/app_${dateStr}_$counter.log';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void write(String message) {
    try {
      // Verifica se mudou o dia
      final now = DateTime.now();
      final dateStr = _formatDate(now);
      if (_currentDate != dateStr) {
        _openLogFile();
      }

      // Verifica se precisa rotacionar por tamanho
      if (_currentFilePath != null && File(_currentFilePath!).existsSync()) {
        final fileSize = File(_currentFilePath!).lengthSync();
        final maxSizeBytes = maxFileSizeMB * 1024 * 1024;

        if (fileSize >= maxSizeBytes) {
          _openLogFile();
        }
      }

      _sink?.writeln(message);
    } catch (e) {
      // Silenciosamente ignora erros de escrita para não quebrar a aplicação
      print('⚠️  Erro ao escrever no log: $e');
    }
  }

  void _closeCurrentFile() {
    _sink?.close();
    _sink = null;
  }

  void close() {
    _closeCurrentFile();
  }
}

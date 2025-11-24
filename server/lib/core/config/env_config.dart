import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EnvConfig {
  static DotEnv? _env;
  static bool _loaded = false;

  /// Carrega o arquivo .env
  /// Deve ser chamado no início da aplicação (ex: no main())
  static void load({String filename = '.env'}) {
    if (_loaded) return;

    _env = DotEnv(includePlatformEnvironment: true);

    // Tenta carregar o arquivo .env se existir
    final envFile = File(filename);
    if (envFile.existsSync()) {
      _env!.load([filename]);
    }

    _loaded = true;
  }

  /// Obtém uma variável de ambiente
  /// Primeiro tenta do arquivo .env, depois das variáveis de ambiente do sistema
  static String? get(String key) {
    if (!_loaded) {
      // Se não carregou o .env, tenta apenas variáveis de ambiente do sistema
      return Platform.environment[key];
    }
    // DotEnv já inclui variáveis de ambiente do sistema quando includePlatformEnvironment: true
    return _env?[key];
  }

  /// Obtém uma variável de ambiente com valor padrão
  static String getOrDefault(String key, String defaultValue) {
    return get(key) ?? defaultValue;
  }

  /// Obtém uma variável de ambiente como int
  static int? getInt(String key) {
    final value = get(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Obtém uma variável de ambiente como int com valor padrão
  static int getIntOrDefault(String key, int defaultValue) {
    return getInt(key) ?? defaultValue;
  }

  /// Obtém uma variável de ambiente como bool
  static bool? getBool(String key) {
    final value = get(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Obtém uma variável de ambiente como bool com valor padrão
  static bool getBoolOrDefault(String key, bool defaultValue) {
    return getBool(key) ?? defaultValue;
  }
}

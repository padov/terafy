import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';

/// Pool de conexões para reutilizar conexões do PostgreSQL
///
/// Evita criar uma nova conexão a cada requisição, reduzindo
/// o número de conexões abertas e melhorando performance.
class ConnectionPool {
  static final ConnectionPool _instance = ConnectionPool._internal();
  factory ConnectionPool() => _instance;
  ConnectionPool._internal();

  final List<Connection> _availableConnections = [];
  final List<Connection> _inUseConnections = [];
  final int _maxPoolSize = 10; // Máximo de conexões no pool
  final int _minPoolSize = 2; // Mínimo de conexões no pool
  final Duration _idleTimeout = const Duration(minutes: 4); // Timeout para conexões idle (menor que o do PostgreSQL)
  final Map<Connection, DateTime> _connectionLastUsed = {}; // Rastreia quando cada conexão foi usada pela última vez
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// Inicializa o pool criando conexões iniciais
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Inicializando pool de conexões (min: $_minPoolSize, max: $_maxPoolSize)');

    // Cria conexões iniciais
    for (int i = 0; i < _minPoolSize; i++) {
      try {
        final conn = await _createConnection();
        _availableConnections.add(conn);
      } catch (e) {
        AppLogger.error('Erro ao criar conexão inicial no pool: $e');
      }
    }

    _isInitialized = true;

    // Inicia timer de limpeza de conexões idle (a cada 30 segundos)
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) => _cleanupIdleConnections());

    AppLogger.info('Pool de conexões inicializado com ${_availableConnections.length} conexões');
  }

  /// Obtém uma conexão do pool
  ///
  /// Se houver conexão disponível, retorna ela.
  /// Caso contrário, cria uma nova (até o limite máximo).
  /// Se o pool estiver cheio, aguarda até uma conexão ficar disponível.
  Future<Connection> getConnection() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Limpa conexões idle antes de obter uma nova
    await _cleanupIdleConnections();

    // Tenta obter uma conexão disponível
    if (_availableConnections.isNotEmpty) {
      final conn = _availableConnections.removeAt(0);
      _inUseConnections.add(conn);
      _connectionLastUsed[conn] = DateTime.now();
      return conn;
    }

    // Se não há conexões disponíveis mas ainda não atingiu o máximo, cria uma nova
    final totalConnections = _availableConnections.length + _inUseConnections.length;
    if (totalConnections < _maxPoolSize) {
      try {
        final conn = await _createConnection();
        _inUseConnections.add(conn);
        _connectionLastUsed[conn] = DateTime.now();
        AppLogger.info('Nova conexão criada no pool (total: ${totalConnections + 1})');
        return conn;
      } catch (e) {
        AppLogger.error('Erro ao criar nova conexão: $e');
        rethrow;
      }
    }

    // Pool cheio, aguarda uma conexão ficar disponível
    // Em produção, pode implementar uma fila de espera aqui
    AppLogger.warning('Pool de conexões cheio, aguardando conexão disponível...');
    while (_availableConnections.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final conn = _availableConnections.removeAt(0);
    _inUseConnections.add(conn);
    _connectionLastUsed[conn] = DateTime.now();
    return conn;
  }

  /// Devolve uma conexão ao pool
  ///
  /// A conexão volta para o pool de disponíveis e pode ser reutilizada.
  void releaseConnection(Connection conn) {
    if (!_inUseConnections.contains(conn)) {
      AppLogger.warning('Tentativa de devolver conexão que não está em uso');
      return;
    }

    _inUseConnections.remove(conn);

    // Atualiza timestamp de última utilização
    _connectionLastUsed[conn] = DateTime.now();

    // Se o pool já tem muitas conexões disponíveis, fecha esta
    if (_availableConnections.length >= _maxPoolSize) {
      _closeConnection(conn);
      _connectionLastUsed.remove(conn);
      return;
    }

    _availableConnections.add(conn);
  }

  /// Cria uma nova conexão
  Future<Connection> _createConnection() async {
    final host = EnvConfig.getOrDefault('DB_HOST', 'localhost');
    final port = EnvConfig.getIntOrDefault('DB_PORT', 5432);
    final database = EnvConfig.getOrDefault('DB_NAME', 'terafy_db');
    final username = EnvConfig.getOrDefault('DB_USER', 'postgres');
    final password = EnvConfig.getOrDefault('DB_PASSWORD', '');

    final sslModeRaw = EnvConfig.get('DB_SSL_MODE');
    final sslModeStr = (sslModeRaw ?? 'disable').toLowerCase().trim();
    final sslMode = (sslModeStr == 'require' || sslModeStr == 'required') ? SslMode.require : SslMode.disable;

    return Connection.open(
      Endpoint(host: host, port: port, database: database, username: username, password: password),
      settings: ConnectionSettings(sslMode: sslMode),
    );
  }

  /// Limpa conexões idle do pool
  Future<void> _cleanupIdleConnections() async {
    final now = DateTime.now();
    final connectionsToRemove = <Connection>[];

    // Remove conexões disponíveis que estão idle há muito tempo
    for (final conn in _availableConnections) {
      final lastUsed = _connectionLastUsed[conn];
      if (lastUsed != null && now.difference(lastUsed) > _idleTimeout) {
        connectionsToRemove.add(conn);
      }
    }

    // Fecha conexões idle
    for (final conn in connectionsToRemove) {
      _availableConnections.remove(conn);
      _connectionLastUsed.remove(conn);
      _closeConnection(conn);
    }

    // Se ainda há muitas conexões disponíveis, fecha as mais antigas
    if (_availableConnections.length > _minPoolSize) {
      // Ordena por última utilização (mais antigas primeiro)
      _availableConnections.sort((a, b) {
        final lastUsedA = _connectionLastUsed[a] ?? DateTime(1970);
        final lastUsedB = _connectionLastUsed[b] ?? DateTime(1970);
        return lastUsedA.compareTo(lastUsedB);
      });

      final excess = _availableConnections.length - _minPoolSize;
      for (int i = 0; i < excess; i++) {
        final conn = _availableConnections.removeAt(0);
        _connectionLastUsed.remove(conn);
        _closeConnection(conn);
      }
    }
  }

  /// Fecha uma conexão
  Future<void> _closeConnection(Connection conn) async {
    try {
      await conn.close();
    } catch (e) {
      // Ignora erros ao fechar conexão (pode já estar fechada)
      AppLogger.warning('Erro ao fechar conexão do pool: $e');
    }
  }

  /// Fecha todas as conexões do pool
  Future<void> closeAll() async {
    _cleanupTimer?.cancel();

    // Fecha todas as conexões disponíveis
    for (final conn in _availableConnections) {
      await _closeConnection(conn);
    }
    _availableConnections.clear();

    // Fecha todas as conexões em uso
    for (final conn in _inUseConnections) {
      await _closeConnection(conn);
    }
    _inUseConnections.clear();

    _connectionLastUsed.clear();
    _isInitialized = false;
    AppLogger.info('Pool de conexões fechado');
  }

  /// Retorna estatísticas do pool
  Map<String, dynamic> getStats() {
    return {
      'available': _availableConnections.length,
      'inUse': _inUseConnections.length,
      'total': _availableConnections.length + _inUseConnections.length,
      'maxPoolSize': _maxPoolSize,
      'minPoolSize': _minPoolSize,
    };
  }
}

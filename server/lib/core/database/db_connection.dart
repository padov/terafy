import 'package:postgres/postgres.dart';
import 'package:server/core/database/connection_pool.dart';

class DBConnection {
  final ConnectionPool _pool = ConnectionPool();

  /// Obtém uma conexão do pool
  ///
  /// IMPORTANTE: A conexão deve ser devolvida ao pool após o uso
  /// usando [releaseConnection]. Use [withConnection] para garantir
  /// que a conexão seja devolvida automaticamente.
  Future<Connection> getConnection() async {
    return await _pool.getConnection();
  }

  /// Executa uma função com uma conexão do pool
  ///
  /// A conexão é automaticamente devolvida ao pool após o uso,
  /// mesmo em caso de erro.
  Future<T> withConnection<T>(Future<T> Function(Connection conn) action) async {
    final conn = await getConnection();
    try {
      return await action(conn);
    } finally {
      _pool.releaseConnection(conn);
    }
  }

  /// Devolve uma conexão ao pool
  ///
  /// Use este método se você obteve a conexão manualmente com [getConnection]
  /// e precisa devolvê-la ao pool.
  void releaseConnection(Connection conn) {
    _pool.releaseConnection(conn);
  }

  /// Inicializa o pool de conexões
  Future<void> initialize() async {
    await _pool.initialize();
  }

  /// Fecha todas as conexões do pool
  Future<void> closeAll() async {
    await _pool.closeAll();
  }
}

import 'package:postgres/postgres.dart';
import 'package:common/common.dart';

/// Helper para configurar o contexto RLS (Row Level Security) no PostgreSQL
///
/// O RLS funciona através de variáveis de sessão que são definidas antes das queries.
/// O PostgreSQL usa essas variáveis nas policies para filtrar automaticamente os dados.
///
/// Exemplo de uso:
/// ```dart
/// final conn = await _dbConnection.getConnection();
/// await setRLSContext(conn, userId: 1, userRole: 'therapist');
/// // Agora todas as queries nesta conexão respeitarão o RLS
/// ```
class RLSContext {
  /// Define o contexto RLS para uma conexão do PostgreSQL
  ///
  /// [conn] - Conexão do PostgreSQL
  /// [userId] - ID do usuário autenticado (obrigatório)
  /// [userRole] - Role do usuário ('therapist', 'patient', 'admin')
  /// [accountId] - ID da conta vinculada (therapist_id ou patient_id)
  ///
  /// Essas variáveis são usadas pelas policies do RLS no PostgreSQL:
  /// ```sql
  /// CREATE POLICY therapist_policy ON therapists
  ///   USING (user_id = current_setting('app.user_id', true)::int);
  /// ```
  static Future<void> setContext({
    required Connection conn,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    // Define o user_id (obrigatório para RLS)
    // Usa SET em vez de SET LOCAL para funcionar fora de transações
    await _setConfig(conn, key: 'app.user_id', value: userId.toString());

    // Define a role se fornecida
    if (userRole != null) {
      await _setConfig(conn, key: 'app.user_role', value: userRole);
    }

    // Define o account_id se fornecido
    if (accountId != null) {
      await _setConfig(
        conn,
        key: 'app.account_id',
        value: accountId.toString(),
      );
    }
  }

  /// Limpa o contexto RLS (útil para queries administrativas)
  ///
  /// Remove todas as variáveis de sessão relacionadas ao RLS
  static Future<void> clearContext(Connection conn) async {
    await conn.execute("RESET app.user_id");
    await conn.execute("RESET app.user_role");
    await conn.execute("RESET app.account_id");
  }

  static Future<void> _setConfig(
    Connection conn, {
    required String key,
    required String value,
  }) {
    return conn.execute(
      Sql.named("SELECT set_config(@key, @value, true)"),
      parameters: {'key': key, 'value': value},
    );
  }
}

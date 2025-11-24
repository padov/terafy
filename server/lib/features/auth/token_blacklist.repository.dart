import '../../../core/database/db_connection.dart';
import 'package:postgres/postgres.dart';
import 'package:common/common.dart';

/// Repository para gerenciar blacklist de tokens
class TokenBlacklistRepository {
  final DBConnection _dbConnection;

  TokenBlacklistRepository(this._dbConnection);

  /// Adiciona um token à blacklist
  ///
  /// [tokenId] - JTI (JWT ID) ou hash do token
  /// [userId] - ID do usuário
  /// [expiresAt] - Quando o token originalmente expiraria
  /// [reason] - Motivo da revogação (opcional)
  Future<void> addToBlacklist({
    required String tokenId,
    required int userId,
    required DateTime expiresAt,
    String? reason,
  }) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          INSERT INTO token_blacklist (
            token_id, user_id, expires_at, reason
          ) VALUES (
            @token_id, @user_id, @expires_at, @reason
          )
          ON CONFLICT (token_id) DO NOTHING;
        '''),
        parameters: {'token_id': tokenId, 'user_id': userId, 'expires_at': expiresAt, 'reason': reason ?? 'logout'},
      );
    });
  }

  /// Verifica se um token está na blacklist
  ///
  /// Retorna true se o token está na blacklist e ainda não expirou
  Future<bool> isBlacklisted(String tokenId) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT COUNT(*) 
          FROM token_blacklist
          WHERE token_id = @token_id 
          AND expires_at > NOW();
        '''),
        parameters: {'token_id': tokenId},
      );

      final count = result.first[0] as int;
      return count > 0;
    });
  }

  /// Remove tokens expirados da blacklist (limpeza)
  Future<int> deleteExpiredTokens() async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute('''
        DELETE FROM token_blacklist
        WHERE expires_at < NOW();
      ''');

      return result.affectedRows;
    });
  }

  /// Adiciona todos os tokens de um usuário à blacklist
  /// (útil para logout de todos os dispositivos)
  Future<void> blacklistAllUserTokens(int userId, {String? reason}) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      // Nota: Isso requer que você tenha uma forma de identificar
      // todos os tokens de um usuário. Uma abordagem seria adicionar
      // um prefixo ao token_id baseado no user_id.
      // Por enquanto, apenas adiciona uma entrada genérica.
      await conn.execute(
        Sql.named('''
          INSERT INTO token_blacklist (
            token_id, user_id, expires_at, reason
          ) VALUES (
            @token_id, @user_id, @expires_at, @reason
          )
          ON CONFLICT (token_id) DO NOTHING;
        '''),
        parameters: {
          'token_id': 'user_$userId',
          'user_id': userId,
          'expires_at': DateTime.now().add(const Duration(days: 1)),
          'reason': reason ?? 'logout_all',
        },
      );
    });
  }
}

import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../core/database/db_connection.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:common/common.dart';

/// Repository para gerenciar refresh tokens
class RefreshTokenRepository {
  final DBConnection _dbConnection;

  RefreshTokenRepository(this._dbConnection);

  /// Cria um hash do token para armazenamento seguro
  String _hashToken(String token) {
    AppLogger.func();
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Cria um novo refresh token
  ///
  /// [userId] - ID do usuário
  /// [token] - Token string (será hasheado antes de armazenar)
  /// [expiresAt] - Data de expiração
  /// [deviceInfo] - Informações do dispositivo (opcional)
  /// [ipAddress] - Endereço IP (opcional)
  ///
  /// Retorna o tokenId (jti do JWT) que foi usado como id no banco
  Future<String> createRefreshToken({
    required int userId,
    required String token,
    required DateTime expiresAt,
    String? deviceInfo,
    String? ipAddress,
  }) async {
    AppLogger.func();
    final tokenHash = _hashToken(token);

    // Extrai o tokenId (jti) do JWT para usar como id no banco
    // Isso garante que o id retornado seja o mesmo que está no JWT
    final tokenId = _extractTokenId(token);
    if (tokenId == null) {
      throw Exception('Token JWT deve ter jti claim');
    }

    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        INSERT INTO refresh_tokens (
          id, user_id, token_hash, expires_at, device_info, ip_address
        ) VALUES (
          @id, @user_id, @token_hash, @expires_at, @device_info, @ip_address
        ) RETURNING id;
      '''),
        parameters: {
          'id': tokenId,
          'user_id': userId,
          'token_hash': tokenHash,
          'expires_at': expiresAt,
          'device_info': deviceInfo,
          'ip_address': ipAddress,
        },
      );

      if (result.isEmpty) {
        throw Exception('Erro ao criar refresh token');
      }

      return result.first[0] as String; // Retorna o tokenId (jti)
    });
  }

  /// Extrai o tokenId (jti) do JWT
  String? _extractTokenId(String token) {
    AppLogger.func();
    // Usa o JwtService para decodificar o token
    final claims = JwtService.decodeToken(token);
    return claims?['jti'] as String?;
  }

  /// Busca um refresh token pelo hash
  ///
  /// Retorna o ID do token se encontrado e válido, null caso contrário
  Future<String?> findTokenByHash(String token) async {
    AppLogger.func();
    final tokenHash = _hashToken(token);

    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT id, revoked, expires_at
          FROM refresh_tokens
          WHERE token_hash = @token_hash;
        '''),
        parameters: {'token_hash': tokenHash},
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      final revoked = row[1] as bool;
      final expiresAt = row[2] as DateTime;

      // Verifica se está revogado ou expirado
      if (revoked || DateTime.now().isAfter(expiresAt)) {
        return null;
      }

      return row[0] as String; // Retorna o UUID
    });
  }

  /// Atualiza o last_used_at de um refresh token
  Future<void> updateLastUsed(String tokenId) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE refresh_tokens
          SET last_used_at = NOW()
          WHERE id = @token_id;
        '''),
        parameters: {'token_id': tokenId},
      );
    });
  }

  /// Revoga um refresh token específico
  Future<void> revokeToken(String tokenId) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE refresh_tokens
          SET revoked = TRUE
          WHERE id = @token_id;
        '''),
        parameters: {'token_id': tokenId},
      );
    });
  }

  /// Revoga todos os refresh tokens de um usuário
  Future<void> revokeAllUserTokens(int userId) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE refresh_tokens
          SET revoked = TRUE
          WHERE user_id = @user_id AND revoked = FALSE;
        '''),
        parameters: {'user_id': userId},
      );
    });
  }

  /// Remove tokens expirados (limpeza)
  Future<int> deleteExpiredTokens() async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute('''
        DELETE FROM refresh_tokens
        WHERE expires_at < NOW();
      ''');

      return result.affectedRows;
    });
  }

  /// Lista todos os refresh tokens ativos de um usuário
  Future<List<Map<String, dynamic>>> getUserTokens(int userId) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT 
            id, expires_at, revoked, device_info, ip_address,
            created_at, last_used_at
          FROM refresh_tokens
          WHERE user_id = @user_id
          ORDER BY created_at DESC;
        '''),
        parameters: {'user_id': userId},
      );

      return result.map((row) {
        return {
          'id': row[0],
          'expires_at': row[1],
          'revoked': row[2],
          'device_info': row[3],
          'ip_address': row[4],
          'created_at': row[5],
          'last_used_at': row[6],
        };
      }).toList();
    });
  }
}

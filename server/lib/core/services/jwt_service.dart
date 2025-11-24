import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:server/core/config/env_config.dart';

class JwtService {
  // Lê a chave secreta do arquivo .env ou variável de ambiente
  static String get _secretKey {
    final envKey = EnvConfig.get('JWT_SECRET_KEY');
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Fallback para desenvolvimento (NUNCA usar em produção!)
    // Em produção, SEMPRE defina JWT_SECRET_KEY no arquivo .env
    const devKey = 'DEV-KEY-ONLY-DO-NOT-USE-IN-PRODUCTION-CHANGE-THIS';
    return devKey;
  }

  // Duração do access token (15 minutos)
  static int get _accessTokenExpirationMinutes {
    return EnvConfig.getIntOrDefault('JWT_ACCESS_TOKEN_EXPIRATION_MINUTES', 15);
  }

  // Duração do refresh token (7 dias)
  static int get _refreshTokenExpirationDays {
    return EnvConfig.getIntOrDefault('JWT_REFRESH_TOKEN_EXPIRATION_DAYS', 7);
  }

  /// Gera um access token JWT (curta duração: 15 minutos)
  ///
  /// [userId] - ID do usuário
  /// [email] - Email do usuário
  /// [role] - Role do usuário
  /// [accountType] - Tipo de conta vinculada (opcional)
  /// [accountId] - ID da conta vinculada (opcional)
  /// [jti] - JWT ID (opcional, para blacklist)
  static String generateAccessToken({
    required int userId,
    required String email,
    required String role,
    String? accountType,
    int? accountId,
    String? jti,
  }) {
    final now = DateTime.now();
    final expiration = now.add(
      Duration(minutes: _accessTokenExpirationMinutes),
    );

    final claims = {
      'sub': userId.toString(), // Subject (user ID)
      'email': email,
      'role': role,
      'account_type': accountType,
      'account_id': accountId,
      'type': 'access', // Tipo do token
      'iat': now.millisecondsSinceEpoch ~/ 1000, // Issued at
      'exp': expiration.millisecondsSinceEpoch ~/ 1000, // Expiration
    };

    // Adiciona JTI se fornecido (para blacklist)
    if (jti != null) {
      claims['jti'] = jti;
    }

    final jwt = JWT(claims);
    return jwt.sign(SecretKey(_secretKey));
  }

  /// Gera um refresh token JWT (longa duração: 7 dias)
  ///
  /// [userId] - ID do usuário
  /// [tokenId] - ID único do refresh token (UUID)
  static String generateRefreshToken({
    required int userId,
    required String tokenId,
  }) {
    final now = DateTime.now();
    final expiration = now.add(Duration(days: _refreshTokenExpirationDays));

    final claims = {
      'sub': userId.toString(), // Subject (user ID)
      'type': 'refresh', // Tipo do token
      'jti': tokenId, // JWT ID (UUID do refresh token)
      'iat': now.millisecondsSinceEpoch ~/ 1000, // Issued at
      'exp': expiration.millisecondsSinceEpoch ~/ 1000, // Expiration
    };

    final jwt = JWT(claims);
    return jwt.sign(SecretKey(_secretKey));
  }

  // Gera um token JWT (método legado - mantido para compatibilidade)
  // @deprecated Use generateAccessToken ou generateRefreshToken
  static String generateToken({
    required int userId,
    required String email,
    required String role,
    String? accountType,
    int? accountId,
  }) {
    return generateAccessToken(
      userId: userId,
      email: email,
      role: role,
      accountType: accountType,
      accountId: accountId,
    );
  }

  // Valida e decodifica um token JWT
  static Map<String, dynamic>? validateToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secretKey));
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null; // Token inválido ou expirado
    }
  }

  // Extrai informações do token sem validar (use apenas quando necessário)
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final jwt = JWT.decode(token);
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/core/services/password_service.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:uuid/uuid.dart';
import 'refresh_token.repository.dart';
import 'token_blacklist.repository.dart';

/// Resultado de uma operação de login
class LoginResult {
  final String authToken;
  final String refreshToken;
  final User user;

  LoginResult({
    required this.authToken,
    required this.refreshToken,
    required this.user,
  });
}

/// Resultado de uma operação de registro
class RegisterResult {
  final String authToken;
  final String refreshToken;
  final User user;
  final String message;

  RegisterResult({
    required this.authToken,
    required this.refreshToken,
    required this.user,
    required this.message,
  });
}

/// Controller responsável pela lógica de autenticação
class AuthController {
  final UserRepository _userRepository;
  final RefreshTokenRepository _refreshTokenRepository;
  final _uuid = const Uuid();

  AuthController(this._userRepository, this._refreshTokenRepository);

  /// Realiza login do usuário
  ///
  /// Retorna [LoginResult] em caso de sucesso
  /// Lança [AuthException] em caso de erro
  Future<LoginResult> login(String email, String password) async {
    AppLogger.func();

    // Busca usuário por email
    final user = await _userRepository.getUserByEmail(email);

    if (user == null) {
      throw AuthException('Credenciais inválidas', 401);
    }

    // Verifica senha
    if (user.passwordHash == null ||
        !PasswordService.verifyPassword(password, user.passwordHash!)) {
      throw AuthException('Credenciais inválidas', 401);
    }

    // Verifica se a conta está ativa
    AppLogger.variable('User status', user.status);
    if (user.status != 'active') {
      throw AuthException('Conta suspensa ou cancelada', 403);
    }

    // Atualiza último login
    await _userRepository.updateLastLogin(user.id!);

    // Gera refresh token ID (UUID)
    final refreshTokenId = _uuid.v4();
    final refreshTokenExpiresAt = DateTime.now().add(const Duration(days: 7));

    // Gera refresh token string
    final refreshTokenString = JwtService.generateRefreshToken(
      userId: user.id!,
      tokenId: refreshTokenId,
    );

    // Armazena refresh token no banco
    await _refreshTokenRepository.createRefreshToken(
      userId: user.id!,
      token: refreshTokenString,
      expiresAt: refreshTokenExpiresAt,
    );

    // Gera access token (curta duração: 15 minutos)
    final accessToken = JwtService.generateAccessToken(
      userId: user.id!,
      email: user.email,
      role: user.role,
      accountType: user.accountType,
      accountId: user.accountId,
      jti: _uuid.v4(), // JTI para blacklist
    );

    return LoginResult(
      authToken: accessToken,
      refreshToken: refreshTokenString,
      user: user,
    );
  }

  /// Registra um novo usuário
  ///
  /// Retorna [RegisterResult] em caso de sucesso
  /// Lança [AuthException] em caso de erro
  Future<RegisterResult> register(String email, String password) async {
    AppLogger.func();

    // Validação básica de senha
    if (password.length < 6) {
      throw AuthException('Senha deve ter no mínimo 6 caracteres', 400);
    }

    // Verifica se o email já existe
    final existingUser = await _userRepository.getUserByEmail(email);
    if (existingUser != null) {
      throw AuthException('Email já cadastrado', 400);
    }

    // Cria hash da senha
    final passwordHash = PasswordService.hashPassword(password);

    // Cria usuário sem accountType e accountId (serão preenchidos após completar perfil)
    final newUser = User(
      email: email,
      passwordHash: passwordHash,
      role: 'therapist', // Por padrão, registros são de terapeutas
      accountType: null, // Será preenchido quando o perfil for completado
      accountId: null, // Será preenchido quando o perfil for completado
      status: 'active',
      emailVerified: false,
    );

    final createdUser = await _userRepository.createUser(newUser);

    // Gera refresh token ID (UUID)
    final refreshTokenId = _uuid.v4();
    final refreshTokenExpiresAt = DateTime.now().add(const Duration(days: 7));

    // Gera refresh token string
    final refreshTokenString = JwtService.generateRefreshToken(
      userId: createdUser.id!,
      tokenId: refreshTokenId,
    );

    // Armazena refresh token no banco
    await _refreshTokenRepository.createRefreshToken(
      userId: createdUser.id!,
      token: refreshTokenString,
      expiresAt: refreshTokenExpiresAt,
    );

    // Gera access token (curta duração: 15 minutos)
    final accessToken = JwtService.generateAccessToken(
      userId: createdUser.id!,
      email: createdUser.email,
      role: createdUser.role,
      accountType: createdUser.accountType,
      accountId: createdUser.accountId,
      jti: _uuid.v4(), // JTI para blacklist
    );

    return RegisterResult(
      authToken: accessToken,
      refreshToken: refreshTokenString,
      user: createdUser,
      message:
          'Usuário criado com sucesso. Complete seu cadastro como terapeuta.',
    );
  }

  /// Retorna informações do usuário autenticado
  ///
  /// Retorna [User] em caso de sucesso
  /// Lança [AuthException] em caso de erro
  Future<User> getCurrentUser(String token) async {
    AppLogger.func();
    final claims = JwtService.validateToken(token);

    if (claims == null) {
      throw AuthException('Token inválido ou expirado', 401);
    }

    final userId = int.parse(claims['sub'] as String);
    final user = await _userRepository.getUserById(userId);

    if (user == null) {
      throw AuthException('Usuário não encontrado', 404);
    }

    return user;
  }

  /// Renova o access token usando um refresh token
  ///
  /// [refreshToken] - Refresh token válido
  ///
  /// Retorna novo access token e refresh token
  /// Lança [AuthException] em caso de erro
  Future<Map<String, String>> refreshAccessToken(String refreshToken) async {
    AppLogger.func();
    // Valida o refresh token
    final claims = JwtService.validateToken(refreshToken);

    if (claims == null) {
      throw AuthException('Refresh token inválido ou expirado', 401);
    }

    // Verifica se é realmente um refresh token
    final tokenType = claims['type'] as String?;
    if (tokenType != 'refresh') {
      throw AuthException('Token inválido. Use refresh token.', 401);
    }

    // Extrai informações do token
    final userId = int.parse(claims['sub'] as String);
    final tokenId = claims['jti'] as String?;

    if (tokenId == null) {
      throw AuthException('Refresh token inválido', 401);
    }

    // Verifica se o refresh token existe e está válido no banco
    final storedTokenId = await _refreshTokenRepository.findTokenByHash(
      refreshToken,
    );

    if (storedTokenId == null || storedTokenId != tokenId) {
      throw AuthException('Refresh token inválido ou revogado', 401);
    }

    // Busca usuário
    final user = await _userRepository.getUserById(userId);
    if (user == null) {
      throw AuthException('Usuário não encontrado', 404);
    }

    // Verifica se a conta está ativa
    if (user.status != 'active') {
      throw AuthException('Conta suspensa ou cancelada', 403);
    }

    // Atualiza last_used_at do refresh token
    await _refreshTokenRepository.updateLastUsed(tokenId);

    // Gera novo access token
    final newAccessToken = JwtService.generateAccessToken(
      userId: user.id!,
      email: user.email,
      role: user.role,
      accountType: user.accountType,
      accountId: user.accountId,
      jti: _uuid.v4(), // Novo JTI para blacklist
    );

    return {
      'access_token': newAccessToken,
      'refresh_token': refreshToken, // Mantém o mesmo refresh token
    };
  }

  /// Revoga um refresh token (logout)
  ///
  /// [refreshToken] - Refresh token a ser revogado
  /// [accessToken] - Access token a ser adicionado à blacklist (opcional)
  /// [blacklistRepository] - Repository para blacklist (opcional)
  Future<void> revokeRefreshToken(
    String refreshToken, {
    String? accessToken,
    TokenBlacklistRepository? blacklistRepository,
  }) async {
    AppLogger.func();
    // Valida o refresh token
    final claims = JwtService.validateToken(refreshToken);
    if (claims == null) {
      return; // Token já inválido, não precisa revogar
    }

    final tokenId = claims['jti'] as String?;
    if (tokenId != null) {
      await _refreshTokenRepository.revokeToken(tokenId);
    }

    // Adiciona access token à blacklist se fornecido
    if (accessToken != null && blacklistRepository != null) {
      final accessClaims = JwtService.validateToken(accessToken);
      if (accessClaims != null) {
        final jti = accessClaims['jti'] as String?;
        final userId = int.tryParse(accessClaims['sub'] as String? ?? '');
        final exp = accessClaims['exp'] as int?;

        if (jti != null && userId != null && exp != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          await blacklistRepository.addToBlacklist(
            tokenId: jti,
            userId: userId,
            expiresAt: expiresAt,
            reason: 'logout',
          );
        }
      }
    }
  }
}

/// Exceção customizada para erros de autenticação
class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, this.statusCode);

  @override
  String toString() => message;
}

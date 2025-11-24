import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/features/auth/refresh_token.repository.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/services/jwt_service.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError(
      'Use TestUserRepository para testes com dados mockados',
    );
  }
}

// Classe auxiliar para testes que simula o comportamento do UserRepository
class TestUserRepository extends UserRepository {
  final List<User> _users = [];
  int _lastId = 0;

  TestUserRepository() : super(MockDBConnection());

  @override
  Future<User?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> getUserById(int id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    final newUser = User(
      id: ++_lastId,
      email: user.email,
      passwordHash: user.passwordHash,
      phone: user.phone,
      role: user.role,
      accountType: user.accountType,
      accountId: user.accountId,
      status: user.status,
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneVerified,
      tfaEnabled: user.tfaEnabled,
      tfaSecret: user.tfaSecret,
      tfaMethod: user.tfaMethod,
      tfaBackupCodes: user.tfaBackupCodes,
      tfaVerifiedAt: user.tfaVerifiedAt,
      lastLoginAt: user.lastLoginAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<void> updateLastLogin(int userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = User(
        id: user.id,
        email: user.email,
        passwordHash: user.passwordHash,
        role: user.role,
        accountType: user.accountType,
        accountId: user.accountId,
        status: user.status,
        emailVerified: user.emailVerified,
        lastLoginAt: DateTime.now(),
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<User> updateUserAccount({
    required int userId,
    required String accountType,
    required int accountId,
  }) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Usuário não encontrado');
    }

    final user = _users[index];
    final updated = User(
      id: user.id,
      email: user.email,
      passwordHash: user.passwordHash,
      role: user.role,
      accountType: accountType,
      accountId: accountId,
      status: user.status,
      emailVerified: user.emailVerified,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
    );
    _users[index] = updated;
    return updated;
  }

  void clear() {
    _users.clear();
    _lastId = 0;
  }
}

// Classe auxiliar para testes que simula o RefreshTokenRepository
class TestRefreshTokenRepository extends RefreshTokenRepository {
  final Map<String, String> _tokens = {}; // tokenHash -> tokenId
  final Map<String, DateTime> _expiresAt = {}; // tokenId -> expiresAt
  final Map<String, bool> _revoked = {}; // tokenId -> revoked

  TestRefreshTokenRepository() : super(MockDBConnection());

  @override
  Future<String> createRefreshToken({
    required int userId,
    required String token,
    required DateTime expiresAt,
    String? deviceInfo,
    String? ipAddress,
  }) async {
    // Simula hash do token
    final tokenHash = _hashToken(token);

    // Extrai o tokenId do token JWT (jti claim)
    // O tokenId deve ser o mesmo que está no JWT
    // No repository real, o banco gera um UUID, mas aqui simulamos usando o jti do JWT
    final claims = JwtService.decodeToken(token);
    final tokenId = claims?['jti'] as String?;

    if (tokenId == null) {
      throw Exception('Token JWT deve ter jti claim');
    }

    // Armazena: tokenHash -> tokenId
    _tokens[tokenHash] = tokenId;
    _expiresAt[tokenId] = expiresAt;
    _revoked[tokenId] = false;

    // Retorna o tokenId (que é o jti do JWT)
    // No repository real, retorna o UUID gerado pelo banco
    return tokenId;
  }

  @override
  Future<String?> findTokenByHash(String token) async {
    final tokenHash = _hashToken(token);
    final tokenId = _tokens[tokenHash];
    if (tokenId == null) return null;

    // Verifica se está revogado
    if (_revoked[tokenId] == true) return null;

    // Verifica se expirou
    final expiresAt = _expiresAt[tokenId];
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      return null;
    }

    return tokenId;
  }

  @override
  Future<void> revokeToken(String tokenId) async {
    _revoked[tokenId] = true;
  }

  @override
  Future<void> updateLastUsed(String tokenId) async {
    // Simula atualização de last_used_at
    // Em um teste real, você poderia armazenar isso
  }

  String _hashToken(String token) {
    // Usa o mesmo algoritmo do repository real (SHA-256)
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void clear() {
    _tokens.clear();
    _expiresAt.clear();
    _revoked.clear();
  }
}

// Classe auxiliar para testes que simula o TokenBlacklistRepository
class TestTokenBlacklistRepository extends TokenBlacklistRepository {
  final Set<String> _blacklistedTokens = {};

  TestTokenBlacklistRepository() : super(MockDBConnection());

  @override
  Future<void> addToBlacklist({
    required String tokenId,
    required int userId,
    required DateTime expiresAt,
    String? reason,
  }) async {
    _blacklistedTokens.add(tokenId);
  }

  @override
  Future<bool> isBlacklisted(String tokenId) async {
    return _blacklistedTokens.contains(tokenId);
  }

  void clear() {
    _blacklistedTokens.clear();
  }
}

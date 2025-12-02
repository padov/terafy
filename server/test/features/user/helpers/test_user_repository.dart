import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError('Use TestUserRepository para testes com dados mockados');
  }
}

// Classe auxiliar para testes que simula o comportamento do UserRepository
class TestUserRepository extends UserRepository {
  final List<User> _users = [];
  int _lastId = 0;

  TestUserRepository() : super(MockDBConnection());

  @override
  Future<List<User>> getAllUsers() async {
    return List<User>.from(_users);
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
  Future<User?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    // Valida email único
    if (_users.any((u) => u.email == user.email)) {
      throw Exception('Email já está em uso');
    }

    final now = DateTime.now();
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
      createdAt: now,
      updatedAt: now,
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<User> updateUserAccount({required int userId, required String accountType, required int accountId}) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Usuário não encontrado');
    }

    final user = _users[index];
    final updated = User(
      id: user.id,
      email: user.email,
      passwordHash: user.passwordHash,
      phone: user.phone,
      role: user.role,
      accountType: accountType,
      accountId: accountId,
      status: user.status,
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneVerified,
      tfaEnabled: user.tfaEnabled,
      tfaSecret: user.tfaSecret,
      tfaMethod: user.tfaMethod,
      tfaBackupCodes: user.tfaBackupCodes,
      tfaVerifiedAt: user.tfaVerifiedAt,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
    );
    _users[index] = updated;
    return updated;
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
        lastLoginAt: DateTime.now(),
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  void clear() {
    _users.clear();
    _lastId = 0;
  }
}

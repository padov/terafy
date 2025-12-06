import 'package:common/common.dart';
import '../../../core/database/db_connection.dart';
import 'package:postgres/postgres.dart';

class UserRepository {
  final DBConnection _dbConnection;

  UserRepository(this._dbConnection);

  Future<List<User>> getAllUsers() async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute('''
          SELECT 
            id,
            email,
            password_hash,
            phone,
            role::text as role,
            account_type::text as account_type,
            account_id,
            status::text as status,
            last_login_at,
            email_verified,
            phone_verified,
            tfa_enabled,
            tfa_secret,
            tfa_method::text as tfa_method,
            tfa_backup_codes,
            tfa_verified_at,
            created_at,
            updated_at
          FROM users 
          ORDER BY created_at DESC
        ''');

      final users = results.map((row) {
        final map = row.toColumnMap();
        return User.fromMap(map);
      }).toList();

      return users;
    });
  }

  Future<User?> getUserById(int id) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            email,
            password_hash,
            phone,
            role::text as role,
            account_type::text as account_type,
            account_id,
            status::text as status,
            last_login_at,
            email_verified,
            phone_verified,
            tfa_enabled,
            tfa_secret,
            tfa_method::text as tfa_method,
            tfa_backup_codes,
            tfa_verified_at,
            created_at,
            updated_at
          FROM users 
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return User.fromMap(map);
    });
  }

  Future<User?> getUserByEmail(String email) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            email,
            password_hash,
            phone,
            role::text as role,
            account_type::text as account_type,
            account_id,
            status::text as status,
            last_login_at,
            email_verified,
            phone_verified,
            tfa_enabled,
            tfa_secret,
            tfa_method::text as tfa_method,
            tfa_backup_codes,
            tfa_verified_at,
            created_at,
            updated_at
          FROM users 
          WHERE email = @email
        '''),
        parameters: {'email': email},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return User.fromMap(map);
    });
  }

  Future<User> createUser(User user) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO users (
            email, password_hash, phone, role, account_type, account_id, status, 
            email_verified, phone_verified, tfa_enabled, tfa_secret, tfa_method, 
            tfa_backup_codes, tfa_verified_at
          ) VALUES (
            @email, @password_hash, @phone, @role, @account_type, @account_id, @status, 
            @email_verified, @phone_verified, @tfa_enabled, @tfa_secret, @tfa_method, 
            @tfa_backup_codes, @tfa_verified_at
          ) RETURNING 
            id,
            email,
            password_hash,
            phone,
            role::text as role,
            account_type::text as account_type,
            account_id,
            status::text as status,
            last_login_at,
            email_verified,
            phone_verified,
            tfa_enabled,
            tfa_secret,
            tfa_method::text as tfa_method,
            tfa_backup_codes,
            tfa_verified_at,
            created_at,
            updated_at
        '''),
        parameters: {
          'email': user.email,
          'password_hash': user.passwordHash,
          'phone': user.phone,
          'role': user.role,
          'account_type': user.accountType,
          'account_id': user.accountId,
          'status': user.status,
          'email_verified': user.emailVerified,
          'phone_verified': user.phoneVerified,
          'tfa_enabled': user.tfaEnabled,
          'tfa_secret': user.tfaSecret,
          'tfa_method': user.tfaMethod,
          'tfa_backup_codes': user.tfaBackupCodes,
          'tfa_verified_at': user.tfaVerifiedAt,
        },
      );

      if (result.isEmpty) {
        throw Exception('Erro ao criar usuário, nenhum dado retornado.');
      }

      final map = result.first.toColumnMap();
      return User.fromMap(map);
    });
  }

  Future<void> updateLastLogin(int userId) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE users 
          SET last_login_at = NOW(), updated_at = NOW()
          WHERE id = @id;
        '''),
        parameters: {'id': userId},
      );
    });
  }

  Future<User> updateUserAccount({required int userId, required String accountType, required int accountId}) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          UPDATE users 
          SET account_type = @account_type,
              account_id = @account_id,
              updated_at = NOW()
          WHERE id = @id
          RETURNING 
            id,
            email,
            password_hash,
            phone,
            role::text as role,
            account_type::text as account_type,
            account_id,
            status::text as status,
            last_login_at,
            email_verified,
            phone_verified,
            tfa_enabled,
            tfa_secret,
            tfa_method::text as tfa_method,
            tfa_backup_codes,
            tfa_verified_at,
            created_at,
            updated_at
        '''),
        parameters: {'id': userId, 'account_type': accountType, 'account_id': accountId},
      );

      if (result.isEmpty) {
        throw Exception('Erro ao atualizar conta do usuário, nenhum dado retornado.');
      }

      final map = result.first.toColumnMap();
      return User.fromMap(map);
    });
  }
}

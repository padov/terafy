import 'dart:io';
import 'package:test/test.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';
import 'package:server/core/config/env_config.dart';

void main() {
  group('RLSContext Integration Tests', () {
    late DBConnection dbConnection;

    setUpAll(() async {
      final envTestFile = File('.env.test');
      if (!envTestFile.existsSync()) {
        throw StateError('Arquivo .env.test não encontrado. Execute ./scripts/test-db.sh start primeiro.');
      }
      EnvConfig.load(filename: '.env.test');

      dbConnection = DBConnection();
      await dbConnection.initialize();
    });

    tearDownAll(() async {
      await dbConnection.closeAll();
    });

    test('setContext() deve definir variáveis de sessão', () async {
      await dbConnection.withConnection((conn) async {
        // Act
        await RLSContext.setContext(conn: conn, userId: 123, userRole: 'therapist', accountId: 456);

        // Assert
        final userIdResult = await conn.execute("SELECT current_setting('app.user_id', true)");
        expect(userIdResult.first.first, equals('123'));

        final userRoleResult = await conn.execute("SELECT current_setting('app.user_role', true)");
        expect(userRoleResult.first.first, equals('therapist'));

        final accountIdResult = await conn.execute("SELECT current_setting('app.account_id', true)");
        expect(accountIdResult.first.first, equals('456'));
      });
    });

    test('clearContext() deve limpar variáveis de sessão', () async {
      await dbConnection.withConnection((conn) async {
        // Arrange
        await RLSContext.setContext(conn: conn, userId: 123);

        // Act
        await RLSContext.clearContext(conn);

        // Assert
        final userIdResult = await conn.execute("SELECT current_setting('app.user_id', true)");
        final userId = userIdResult.first.first;
        expect(userId == null || userId == '', isTrue);

        final userRoleResult = await conn.execute("SELECT current_setting('app.user_role', true)");
        final userRole = userRoleResult.first.first;
        expect(userRole == null || userRole == '', isTrue);
      });
    });
  });
}

import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'dart:io';

/// Helper para configurar banco de dados de teste
class IntegrationTestDB {
  static const String testDatabase = 'terafy_test_db';
  static const String testUser = 'postgres';
  static const String testPassword = 'mysecretpassword';
  static const String testHost = 'localhost';
  static const int testPort = 5432;

  /// Cria uma conexão com o banco de teste
  static Future<Connection> createTestConnection() async {
    return await Connection.open(
      Endpoint(
        host: testHost,
        port: testPort,
        database: testDatabase,
        username: testUser,
        password: testPassword,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  /// Executa migrations no banco de teste
  static Future<void> runMigrations() async {
    final conn = await createTestConnection();

    try {
      // Lista de migrations na ordem
      final migrations = [
        '20251102180000_create_therapists_table.sql',
        '20251102190000_create_plans_and_subscriptions.sql',
        '20251103000000_create_users_table.sql',
        '20251102000003_add_user_id_to_therapists.sql',
        '20251104000000_enable_rls_therapists.sql',
        '20251102000001_create_refresh_tokens_table.sql',
        '20251102000002_create_token_blacklist_table.sql',
        '20251102000008_create_patients_table.sql',
        '20251102000009_enable_rls_patients.sql',
        '20251102000010_create_therapist_schedule.sql',
        '20251112090000_update_patient_trigger.sql',
        '20251112093000_add_parent_to_appointments.sql',
      ];

      for (final migration in migrations) {
        final file = File('server/db/migrations/$migration');
        if (!file.existsSync()) {
          print('⚠️  Migration não encontrada: $migration');
          continue;
        }

        final content = await file.readAsString();
        // Separa os comandos por migrate:up
        final upSection = content
            .split('-- migrate:up')[1]
            .split('-- migrate:down')[0];

        // Executa cada comando SQL separadamente
        final commands = upSection
            .split(';')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty && !c.startsWith('--'))
            .toList();

        for (final command in commands) {
          if (command.trim().isNotEmpty) {
            try {
              await conn.execute(command);
            } catch (e) {
              // Ignora erros de "já existe" (tabelas, tipos, etc.)
              if (!e.toString().contains('already exists') &&
                  !e.toString().contains('duplicate')) {
                print(
                  '⚠️  Erro ao executar comando: ${command.substring(0, 50)}...',
                );
                print('   Erro: $e');
              }
            }
          }
        }
      }
    } finally {
      await conn.close();
    }
  }

  /// Limpa todas as tabelas do banco de teste
  static Future<void> cleanDatabase() async {
    final conn = await createTestConnection();

    try {
      // Desabilita RLS temporariamente para limpeza
      await conn.execute('SET session_replication_role = replica;');

      // Limpa tabelas na ordem correta (respeitando foreign keys)
      final tables = [
        'token_blacklist',
        'refresh_tokens',
        'plan_subscriptions',
        'therapists',
        'plans',
        'users',
      ];

      for (final table in tables) {
        try {
          await conn.execute('TRUNCATE TABLE $table CASCADE;');
        } catch (e) {
          // Ignora se a tabela não existe
          if (!e.toString().contains('does not exist')) {
            print('⚠️  Erro ao limpar tabela $table: $e');
          }
        }
      }

      // Reabilita RLS
      await conn.execute('SET session_replication_role = DEFAULT;');
    } finally {
      await conn.close();
    }
  }

  /// Cria o banco de teste se não existir
  static Future<void> ensureTestDatabase() async {
    // Conecta ao banco postgres padrão para criar o banco de teste
    final adminConn = await Connection.open(
      Endpoint(
        host: testHost,
        port: testPort,
        database: 'postgres',
        username: testUser,
        password: testPassword,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      // Verifica se o banco existe
      final result = await adminConn.execute(
        "SELECT 1 FROM pg_database WHERE datname = '$testDatabase'",
      );

      if (result.isEmpty) {
        // Cria o banco de teste
        await adminConn.execute('CREATE DATABASE $testDatabase');
        print('✅ Banco de teste criado: $testDatabase');
      }
    } finally {
      await adminConn.close();
    }
  }

  /// Setup completo: cria banco, executa migrations
  static Future<void> setup() async {
    await ensureTestDatabase();
    await runMigrations();
    await cleanDatabase();
  }

  /// Teardown: limpa dados
  static Future<void> teardown() async {
    await cleanDatabase();
  }
}

/// DBConnection específico para testes de integração
class TestDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    return await IntegrationTestDB.createTestConnection();
  }
}

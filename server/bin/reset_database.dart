import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:server/core/config/env_config.dart';

/// Script para dropar e recriar o banco de dados executando todas as migrations
///
/// Uso:
///   dart run bin/reset_database.dart
///
/// Este script:
/// 1. Conecta ao banco postgres (padrão) usando as variáveis de ambiente
/// 2. Termina todas as conexões ao banco terafy_db
/// 3. Dropa o banco terafy_db completamente
/// 4. Cria o banco terafy_db novamente
/// 5. Executa todas as migrations na ordem correta
void main() async {
  print('🔄 Resetando banco de dados...\n');

  // Carrega variáveis de ambiente
  EnvConfig.load();

  final host = EnvConfig.getOrDefault('DB_HOST', 'localhost');
  final port = EnvConfig.getIntOrDefault('DB_PORT', 5432);
  final database = EnvConfig.getOrDefault('DB_NAME', 'terafy_db');
  final username = EnvConfig.getOrDefault('DB_USER', 'postgres');
  final password = EnvConfig.getOrDefault('DB_PASSWORD', 'mysecretpassword');

  print('📊 Configuração do banco:');
  print('   Host: $host');
  print('   Port: $port');
  print('   Database: $database');
  print('   User: $username\n');

  // Passo 1: Conecta ao banco postgres para dropar e recriar o banco
  print('🗑️  Removendo banco de dados existente...');
  final adminConn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: 'postgres', // Conecta ao banco padrão
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // Termina todas as conexões ao banco antes de dropar
    await adminConn.execute('''
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '$database'
        AND pid <> pg_backend_pid();
    ''');

    // Dropa o banco se existir
    await adminConn.execute('DROP DATABASE IF EXISTS $database;');
    print('   ✓ Banco $database removido');

    // Cria o banco novamente
    await adminConn.execute('CREATE DATABASE $database;');
    print('   ✓ Banco $database criado\n');
  } catch (e) {
    print('   ⚠️  Erro ao dropar/criar banco: $e');
    // Continua mesmo se der erro (pode ser que o banco não exista)
  } finally {
    await adminConn.close();
  }

  // Passo 2: Conecta ao banco recém-criado e executa migrations
  print('📦 Executando migrations...');
  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    await runMigrations(conn);
    print('✅ Migrations executadas com sucesso\n');

    print('🎉 Banco de dados resetado com sucesso!');
  } catch (e, stackTrace) {
    print('❌ Erro ao resetar banco de dados:');
    print('   $e');
    print('\nStack trace:');
    print(stackTrace);
    exit(1);
  } finally {
    await conn.close();
  }
}

/// Executa todas as migrations na ordem correta
Future<void> runMigrations(Connection conn) async {
  // Lista de migrations na ordem correta
  final migrations = [
    '20251102000001_create_users_table.sql',
    '20251102000002_create_refresh_tokens_table.sql',
    '20251102000003_create_token_blacklist_table.sql',
    '20251102000004_create_therapists_table.sql',
    '20251102000005_add_user_id_to_therapists.sql',
    '20251102000006_enable_rls_therapists.sql',
    '20251102000007_create_plans_and_subscriptions.sql',
    '20251102000008_create_patients_table.sql',
    '20251102000009_enable_rls_patients.sql',
    '20251102000010_create_therapist_schedule.sql',
    '20251112090000_update_patient_trigger.sql',
    '20251112093000_add_parent_to_appointments.sql',
  ];

  for (final migration in migrations) {
    final file = File('server/db/migrations/$migration');
    if (!file.existsSync()) {
      print('   ⚠️  Migration não encontrada: $migration');
      continue;
    }

    print('   📄 Executando: $migration');

    try {
      final content = await file.readAsString();

      // Separa a seção migrate:up
      if (!content.contains('-- migrate:up')) {
        print('      ⚠️  Migration sem seção migrate:up, pulando...');
        continue;
      }

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
            // Ignora erros de "já existe" (pode acontecer em alguns casos)
            if (!e.toString().contains('already exists') &&
                !e.toString().contains('duplicate')) {
              print('      ❌ Erro ao executar comando:');
              print(
                '         ${command.substring(0, command.length > 100 ? 100 : command.length)}...',
              );
              print('         Erro: $e');
              rethrow;
            }
          }
        }
      }

      print('      ✅ $migration executada com sucesso');
    } catch (e) {
      print('      ❌ Erro ao executar $migration: $e');
      rethrow;
    }
  }
}

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
    Endpoint(host: host, port: port, database: database, username: username, password: password),
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
  // Descobre todas as migrations dinamicamente
  final migrationsDir = Directory('db/migrations');

  if (!migrationsDir.existsSync()) {
    print('   ⚠️  Diretório de migrations não encontrado: ${migrationsDir.path}');
    return;
  }

  // Lista todos os arquivos .sql no diretório de migrations
  final migrationFiles =
      migrationsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .map((f) => f.path.split('/').last)
          .where(
            (name) => !name.startsWith('0000000000001_') && !name.startsWith('0000000000002_'),
          ) // Pula migrations de setup
          .toList()
        ..sort(); // Ordena alfabeticamente (que é a ordem cronológica devido ao timestamp)

  print('   📋 Encontradas ${migrationFiles.length} migrations\n');

  for (final migration in migrationFiles) {
    final file = File('db/migrations/$migration');
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

      final upSection = content.split('-- migrate:up')[1].split('-- migrate:down')[0].trim();

      // Divide por ponto-e-vírgula e executa cada comando separadamente
      final statements = upSection
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !s.startsWith('--'))
          .toList();

      try {
        for (final statement in statements) {
          if (statement.isNotEmpty) {
            try {
              await conn.execute(statement);
            } catch (e) {
              // Ignora erros de "já existe"
              if (!e.toString().contains('already exists') && !e.toString().contains('duplicate')) {
                print('      ❌ Erro ao executar statement:');
                print('         ${statement.substring(0, statement.length > 100 ? 100 : statement.length)}...');
                print('         Erro: $e');
                rethrow;
              }
            }
          }
        }
        print('      ✅ $migration executada com sucesso');
      } catch (e) {
        print('      ❌ Erro fatal em $migration: $e');
        rethrow;
      }
    } catch (e) {
      print('      ❌ Erro ao executar $migration: $e');
      rethrow;
    }
  }

  // Aplica todas as functions/triggers
  await applyFunctions(conn);
}

/// Aplica todas as functions e triggers do diretório db/functions
Future<void> applyFunctions(Connection conn) async {
  print('\n🔧 Aplicando functions e triggers...');

  final functionsDir = Directory('db/functions');

  if (!functionsDir.existsSync()) {
    print('   ⚠️  Diretório de functions não encontrado: ${functionsDir.path}');
    return;
  }

  // Lista todos os arquivos .sql no diretório de functions
  final functionFiles =
      functionsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .map((f) => f.path.split('/').last)
          .toList()
        ..sort(); // Ordena alfabeticamente

  print('   📋 Encontradas ${functionFiles.length} functions/triggers\n');

  for (final functionFile in functionFiles) {
    final file = File('db/functions/$functionFile');
    if (!file.existsSync()) {
      print('   ⚠️  Function não encontrada: $functionFile');
      continue;
    }

    print('   🔧 Aplicando: $functionFile');

    try {
      final content = await file.readAsString();

      // Executa o conteúdo completo do arquivo
      // Functions e triggers geralmente são um único bloco SQL
      await conn.execute(content);

      print('      ✅ $functionFile aplicada com sucesso');
    } catch (e) {
      // Ignora erros de "já existe" para functions/triggers
      if (!e.toString().contains('already exists') && !e.toString().contains('duplicate')) {
        print('      ❌ Erro ao aplicar $functionFile: $e');
        rethrow;
      } else {
        print('      ✅ $functionFile já existe (ok)');
      }
    }
  }
}

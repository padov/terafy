import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:server/core/config/env_config.dart';

void main() async {
  EnvConfig.load();
  final host = EnvConfig.getOrDefault('DB_HOST', 'localhost');
  final port = EnvConfig.getIntOrDefault('DB_PORT', 5432);
  final database = EnvConfig.getOrDefault('DB_NAME', 'terafy_db');
  final username = EnvConfig.getOrDefault('DB_USER', 'postgres');
  final password = EnvConfig.getOrDefault('DB_PASSWORD', 'mysecretpassword');

  print('Conectando ao banco de dados...');
  final conn = await Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    final file = File('db/migrations/20260301000001_add_anamnesis_limit.sql');
    final content = await file.readAsString();
    final upSection = content.split('-- migrate:up')[1].split('-- migrate:down')[0].trim();
    final statements = upSection
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();

    for (final statement in statements) {
      if (statement.isNotEmpty) {
        print('Executando: \${statement.substring(0, statement.length > 50 ? 50 : statement.length)}...');
        await conn.execute(statement);
      }
    }
    print('✅ Migration executada com sucesso!');
  } catch (e) {
    print('❌ Erro: $e');
  } finally {
    await conn.close();
  }
}

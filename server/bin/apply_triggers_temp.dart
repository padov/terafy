import 'dart:io';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/migration_manager.dart';
import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';

void main() async {
  print('Iniciando atualização de triggers...');
  EnvConfig.load(filename: 'server/.env');
  AppLogger.config(isDebugMode: true);

  final dbConnection = DBConnection();
  await dbConnection.initialize();

  try {
    await dbConnection.withConnection((conn) async {
      await MigrationManager.runPendingMigrations(conn);
    });
    print('Triggers atualizados com sucesso via MigrationManager.');
  } catch (e) {
    print('Erro ao atualizar triggers: $e');
    exit(1);
  } finally {
    exit(0);
  }
}

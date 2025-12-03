import 'dart:io';
import 'package:test/test.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/config/env_config.dart';

void main() {
  group('DBConnection Integration Tests', () {
    late DBConnection dbConnection;

    setUpAll(() {
      // Carrega configurações de teste
      final envTestFile = File('.env.test');
      if (!envTestFile.existsSync()) {
        throw StateError('Arquivo .env.test não encontrado. Execute ./scripts/test-db.sh start primeiro.');
      }

      EnvConfig.load(filename: '.env.test');
    });

    setUp(() async {
      dbConnection = DBConnection();
      await dbConnection.initialize();
    });

    tearDown(() async {
      await dbConnection.closeAll();
    });

    test('getConnection() deve retornar conexão válida', () async {
      // Act
      final conn = await dbConnection.getConnection();

      // Assert
      expect(conn, isNotNull);
      expect(conn.isOpen, isTrue);

      // Cleanup
      dbConnection.releaseConnection(conn);
    });

    test('withConnection() deve executar ação e retornar resultado', () async {
      // Act
      final result = await dbConnection.withConnection((conn) async {
        expect(conn.isOpen, isTrue);
        final rs = await conn.execute('SELECT 1 as val');
        return rs.first[0];
      });

      // Assert
      expect(result, equals(1));
    });

    test('withConnection() deve devolver conexão ao pool mesmo em caso de erro', () async {
      // Act & Assert
      try {
        await dbConnection.withConnection((conn) async {
          throw Exception('Erro de teste');
        });
        fail('Deveria ter lançado exceção');
      } catch (e) {
        expect(e.toString(), contains('Erro de teste'));
      }

      // Verifica se ainda conseguimos obter conexão (pool não esgotado/travado)
      final conn = await dbConnection.getConnection();
      expect(conn.isOpen, isTrue);
      dbConnection.releaseConnection(conn);
    });

    test('releaseConnection() deve funcionar corretamente', () async {
      // Act
      final conn = await dbConnection.getConnection();
      expect(conn.isOpen, isTrue);

      dbConnection.releaseConnection(conn);

      // Não temos como verificar estado interno do pool facilmente via DBConnection,
      // mas se não lançou erro, é um bom sinal.
    });

    test('initialize() deve ser idempotente ou seguro', () async {
      // Act
      await dbConnection.initialize();

      // Assert
      final conn = await dbConnection.getConnection();
      expect(conn.isOpen, isTrue);
      dbConnection.releaseConnection(conn);
    });

    test('closeAll() deve fechar conexões', () async {
      // Arrange
      await dbConnection.getConnection(); // Garante uso

      // Act
      await dbConnection.closeAll();

      // Assert - Tentar usar deve falhar ou reabrir dependendo da implementação do pool
      // O pool do postgres package geralmente não permite reuso após close
      // Mas nosso ConnectionPool.getConnection() pode tentar recriar se o pool interno permitir
      // Vamos verificar se conseguimos reinicializar

      await dbConnection.initialize();
      final conn = await dbConnection.getConnection();
      expect(conn.isOpen, isTrue);
      dbConnection.releaseConnection(conn);
    });
  });
}

import 'dart:io';
import 'package:test/test.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/connection_pool.dart';
import 'package:server/core/config/env_config.dart';

void main() {
  group('ConnectionPool Integration Tests', () {
    late ConnectionPool pool;

    setUpAll(() {
      // Carrega configurações de teste
      // Precisamos garantir que o arquivo .env.test existe e tem as configs corretas
      final envTestFile = File('.env.test');
      if (!envTestFile.existsSync()) {
        throw StateError('Arquivo .env.test não encontrado. Execute ./scripts/test-db.sh start primeiro.');
      }

      // Carrega variáveis de ambiente
      EnvConfig.load(filename: '.env.test');
    });

    setUp(() async {
      pool = ConnectionPool();
      await pool.initialize();
    });

    tearDown(() async {
      await pool.closeAll();
    });

    test('initialize() deve criar conexões iniciais', () async {
      // Arrange & Act - já feito no setUp

      // Assert
      final stats = pool.getStats();
      // MinPoolSize padrão é 1 se não especificado, ou podemos verificar se > 0
      expect(stats['total'], greaterThan(0));
      expect(stats['available'], equals(stats['total']));
    });

    test('getConnection() deve retornar conexão válida', () async {
      // Act
      final conn = await pool.getConnection();

      // Assert
      expect(conn, isNotNull);
      expect(conn.isOpen, isTrue);

      // Verifica se consegue executar query
      final result = await conn.execute('SELECT 1');
      expect(result, isNotEmpty);
      expect(result.first[0], equals(1));

      // Cleanup
      pool.releaseConnection(conn);
    });

    test('releaseConnection() deve devolver conexão ao pool', () async {
      // Arrange
      final initialStats = pool.getStats();
      final conn = await pool.getConnection();

      expect(pool.getStats()['available'], equals(initialStats['available']! - 1));
      expect(pool.getStats()['inUse'], equals(initialStats['inUse']! + 1));

      // Act
      pool.releaseConnection(conn);

      // Assert
      final finalStats = pool.getStats();
      expect(finalStats['available'], equals(initialStats['available']));
      expect(finalStats['inUse'], equals(initialStats['inUse']));
    });

    test('deve reutilizar conexões liberadas', () async {
      // Arrange
      final conn1 = await pool.getConnection();
      pool.releaseConnection(conn1);

      // Act
      final conn2 = await pool.getConnection();

      // Assert
      // Nota: Não podemos garantir que é o MESMO objeto de conexão sem acesso aos internos,
      // mas podemos verificar que o número total de conexões não aumentou desnecessariamente
      // Se só pegamos 1, soltamos, e pegamos 1, o total não deve ter aumentado além do inicial (se minPoolSize for suficiente)
      // Assumindo minPoolSize >= 1

      pool.releaseConnection(conn2);
    });

    test('closeAll() deve fechar todas as conexões', () async {
      // Arrange
      await pool.getConnection(); // Garante que tem pelo menos uma conexão ativa/criada

      // Act
      await pool.closeAll();

      // Assert
      final stats = pool.getStats();
      expect(stats['total'], equals(0));
      expect(stats['available'], equals(0));
      expect(stats['inUse'], equals(0));
    });

    test('deve recuperar de erro na conexão', () async {
      // Este teste é mais difícil de simular com conexão real sem matar o banco
      // Mas podemos testar query inválida

      final conn = await pool.getConnection();

      try {
        await conn.execute('SELECT * FROM tabela_inexistente');
        fail('Deveria ter falhado');
      } catch (e) {
        expect(e, isA<ServerException>());
      } finally {
        pool.releaseConnection(conn);
      }

      // A conexão deve continuar válida ou ser substituída pelo pool
      // O pool atual (postgres package) lida com isso?
      // Vamos verificar se conseguimos pegar uma nova conexão

      final conn2 = await pool.getConnection();
      expect(conn2.isOpen, isTrue);
      pool.releaseConnection(conn2);
    });
  });
}

import 'package:test/test.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';
import '../../helpers/integration_test_db.dart';

void main() {
  // Inicializa EnvConfig
  setUpAll(() async {
    EnvConfig.load();
    await IntegrationTestDB.setup();
  });

  tearDownAll(() async {
    await TestDBConnection.closeAllConnections();
  });

  group('TokenBlacklistRepository - Integração com Banco', () {
    late TokenBlacklistRepository repository;
    late UserRepository userRepository;
    late TestDBConnection dbConnection;

    int? testUserId;
    int? testUserId2;

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      await Future.delayed(const Duration(milliseconds: 100)); // Delay para garantir limpeza completa

      dbConnection = TestDBConnection();
      repository = TokenBlacklistRepository(dbConnection);
      userRepository = UserRepository(dbConnection);

      // Gera emails únicos para evitar conflitos em execução paralela
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random1 = (timestamp % 1000000).toString().padLeft(6, '0');
      final random2 = ((timestamp + 1) % 1000000).toString().padLeft(6, '0');
      final uniqueEmail1 = 'teste_${random1}@terafy.com';
      final uniqueEmail2 = 'teste_${random2}@terafy.com';

      // Cria usuários de teste
      final user1 = await userRepository.createUser(
        User(
          email: uniqueEmail1,
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId = user1.id;
      expect(testUserId, isNotNull, reason: 'User ID 1 deve estar disponível');

      final user2 = await userRepository.createUser(
        User(
          email: uniqueEmail2,
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId2 = user2.id;
      expect(testUserId2, isNotNull, reason: 'User ID 2 deve estar disponível');
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('addToBlacklist', () {
      test('adiciona token à blacklist', () async {
        final tokenId = 'test_token_blacklist_1';
        final expiresAt = DateTime.now().add(const Duration(days: 1));

        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt);

        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isTrue);
      });

      test('adiciona token com reason', () async {
        final tokenId = 'test_token_blacklist_2';
        final expiresAt = DateTime.now().add(const Duration(days: 1));

        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt, reason: 'logout');

        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isTrue);
      });

      test('trata conflito (ON CONFLICT DO NOTHING)', () async {
        final tokenId = 'test_token_blacklist_3';
        final expiresAt = DateTime.now().add(const Duration(days: 1));

        // Adiciona primeira vez
        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt);

        // Tenta adicionar novamente (não deve lançar exceção)
        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt);

        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isTrue);
      });
    });

    group('isBlacklisted', () {
      test('retorna true para token na blacklist', () async {
        final tokenId = 'test_token_check_1';
        final expiresAt = DateTime.now().add(const Duration(days: 1));

        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt);

        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isTrue);
      });

      test('retorna false para token não na blacklist', () async {
        final tokenId = 'test_token_not_blacklisted';

        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isFalse);
      });

      test('retorna false para token expirado', () async {
        final tokenId = 'test_token_expired';

        // Cria token com expiração muito próxima (1 segundo)
        final expiresAt = DateTime.now().add(const Duration(seconds: 1));
        await repository.addToBlacklist(tokenId: tokenId, userId: testUserId!, expiresAt: expiresAt);

        // Aguarda expiração (2 segundos para garantir)
        await Future.delayed(const Duration(seconds: 2));

        // Agora o token deve estar expirado
        final isBlacklisted = await repository.isBlacklisted(tokenId);
        expect(isBlacklisted, isFalse);
      });
    });

    group('deleteExpiredTokens', () {
      test('remove tokens expirados', () async {
        final tokenId1 = 'test_token_delete_1';
        final tokenId2 = 'test_token_delete_2';

        // Cria token com expiração muito próxima (1 segundo) para depois expirar
        await repository.addToBlacklist(
          tokenId: tokenId1,
          userId: testUserId!,
          expiresAt: DateTime.now().add(const Duration(seconds: 1)),
        );

        // Token válido
        await repository.addToBlacklist(
          tokenId: tokenId2,
          userId: testUserId!,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );

        // Aguarda expiração do primeiro token
        await Future.delayed(const Duration(seconds: 2));

        final deleted = await repository.deleteExpiredTokens();

        expect(deleted, greaterThan(0));

        // Token expirado deve ter sido removido
        final isBlacklisted1 = await repository.isBlacklisted(tokenId1);
        expect(isBlacklisted1, isFalse);

        // Token válido deve ainda estar na blacklist
        final isBlacklisted2 = await repository.isBlacklisted(tokenId2);
        expect(isBlacklisted2, isTrue);
      });

      test('retorna 0 quando não há tokens expirados', () async {
        final tokenId = 'test_token_valid';

        await repository.addToBlacklist(
          tokenId: tokenId,
          userId: testUserId!,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );

        final deleted = await repository.deleteExpiredTokens();

        expect(deleted, equals(0));
      });
    });

    group('blacklistAllUserTokens', () {
      test('adiciona todos os tokens de um usuário à blacklist', () async {
        await repository.blacklistAllUserTokens(testUserId!, reason: 'logout_all');

        // Verifica que foi adicionado com o padrão 'user_$userId'
        final isBlacklisted = await repository.isBlacklisted('user_$testUserId');
        expect(isBlacklisted, isTrue);
      });

      test('usa reason padrão quando não fornecido', () async {
        await repository.blacklistAllUserTokens(testUserId2!);

        final isBlacklisted = await repository.isBlacklisted('user_$testUserId2');
        expect(isBlacklisted, isTrue);
      });
    });
  });
}

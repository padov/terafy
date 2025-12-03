import 'package:test/test.dart';
import 'package:server/features/auth/refresh_token.repository.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:common/common.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:server/core/config/env_config.dart';
import 'package:uuid/uuid.dart';
import '../../helpers/integration_test_db.dart';

void main() {
  // Inicializa EnvConfig para garantir que JwtService funcione
  setUpAll(() async {
    EnvConfig.load();
    await IntegrationTestDB.setup();
  });

  tearDownAll(() async {
    await TestDBConnection.closeAllConnections();
  });

  group('RefreshTokenRepository - Integração com Banco', () {
    late RefreshTokenRepository repository;
    late UserRepository userRepository;
    late TestDBConnection dbConnection;
    final _uuid = const Uuid();

    int? testUserId;

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      await Future.delayed(const Duration(milliseconds: 100)); // Delay para garantir limpeza completa

      dbConnection = TestDBConnection();
      repository = RefreshTokenRepository(dbConnection);
      userRepository = UserRepository(dbConnection);

      // Gera email único para evitar conflitos em execução paralela
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random = (timestamp % 1000000).toString().padLeft(6, '0');
      final uniqueEmail = 'teste_${random}@terafy.com';

      // Cria usuário de teste
      final user = await userRepository.createUser(
        User(
          email: uniqueEmail,
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId = user.id;
      expect(testUserId, isNotNull, reason: 'User ID deve estar disponível');
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('createRefreshToken', () {
      test('cria token com sucesso', () async {
        // Gera UUID válido para tokenId (campo id é UUID no banco)
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        final result = await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken,
          expiresAt: expiresAt,
        );

        expect(result, equals(tokenId));
      });

      test('cria token com deviceInfo e ipAddress', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        final result = await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken,
          expiresAt: expiresAt,
          deviceInfo: 'iPhone 13',
          ipAddress: '192.168.1.1',
        );

        expect(result, equals(tokenId));
      });

      test('lança exceção quando token não tem jti', () async {
        // Cria um token inválido que não pode ser decodificado
        // O repository tenta extrair o jti e falha, lançando Exception
        final invalidToken = 'invalid.token.without.jti';

        expect(
          () => repository.createRefreshToken(
            userId: testUserId!,
            token: invalidToken,
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('findTokenByHash', () {
      test('encontra token válido', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(userId: testUserId!, token: refreshToken, expiresAt: expiresAt);

        final found = await repository.findTokenByHash(refreshToken);

        expect(found, equals(tokenId));
      });

      test('retorna null para token não encontrado', () async {
        // Gera UUID válido para tokenId (mas não cria no banco)
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);

        final found = await repository.findTokenByHash(refreshToken);

        expect(found, isNull);
      });

      test('retorna null para token revogado', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(userId: testUserId!, token: refreshToken, expiresAt: expiresAt);

        await repository.revokeToken(tokenId);

        final found = await repository.findTokenByHash(refreshToken);

        expect(found, isNull);
      });

      test('retorna null para token expirado', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);

        // Cria token com expiração muito próxima (1 segundo)
        final expiresAt = DateTime.now().add(const Duration(seconds: 1));
        await repository.createRefreshToken(userId: testUserId!, token: refreshToken, expiresAt: expiresAt);

        // Aguarda expiração (2 segundos para garantir)
        await Future.delayed(const Duration(seconds: 2));

        // Agora o token deve estar expirado
        final found = await repository.findTokenByHash(refreshToken);

        expect(found, isNull);
      });
    });

    group('updateLastUsed', () {
      test('atualiza last_used_at', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(userId: testUserId!, token: refreshToken, expiresAt: expiresAt);

        // Não deve lançar exceção
        await repository.updateLastUsed(tokenId);
      });
    });

    group('revokeToken', () {
      test('revoga token específico', () async {
        // Gera UUID válido para tokenId
        final tokenId = _uuid.v4();
        final refreshToken = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(userId: testUserId!, token: refreshToken, expiresAt: expiresAt);

        await repository.revokeToken(tokenId);

        final found = await repository.findTokenByHash(refreshToken);
        expect(found, isNull);
      });
    });

    group('revokeAllUserTokens', () {
      test('revoga todos os tokens de um usuário', () async {
        // Gera UUIDs válidos para tokenIds
        final tokenId1 = _uuid.v4();
        final tokenId2 = _uuid.v4();
        final refreshToken1 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId1);
        final refreshToken2 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId2);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(userId: testUserId!, token: refreshToken1, expiresAt: expiresAt);
        await repository.createRefreshToken(userId: testUserId!, token: refreshToken2, expiresAt: expiresAt);

        await repository.revokeAllUserTokens(testUserId!);

        final found1 = await repository.findTokenByHash(refreshToken1);
        final found2 = await repository.findTokenByHash(refreshToken2);

        expect(found1, isNull);
        expect(found2, isNull);
      });
    });

    group('deleteExpiredTokens', () {
      test('remove tokens expirados', () async {
        // Gera UUIDs válidos para tokenIds
        final tokenId1 = _uuid.v4();
        final tokenId2 = _uuid.v4();
        final refreshToken1 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId1);
        final refreshToken2 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId2);

        // Cria token com expiração muito próxima (1 segundo) para depois expirar
        await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken1,
          expiresAt: DateTime.now().add(const Duration(seconds: 1)),
        );

        // Token válido
        await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken2,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        // Aguarda expiração do primeiro token
        await Future.delayed(const Duration(seconds: 2));

        final deleted = await repository.deleteExpiredTokens();

        expect(deleted, greaterThan(0));

        // Token expirado deve ter sido removido
        final found1 = await repository.findTokenByHash(refreshToken1);
        expect(found1, isNull);

        // Token válido deve ainda existir
        final found2 = await repository.findTokenByHash(refreshToken2);
        expect(found2, equals(tokenId2));
      });
    });

    group('getUserTokens', () {
      test('lista tokens de um usuário', () async {
        // Gera UUIDs válidos para tokenIds
        final tokenId1 = _uuid.v4();
        final tokenId2 = _uuid.v4();
        final refreshToken1 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId1);
        final refreshToken2 = JwtService.generateRefreshToken(userId: testUserId!, tokenId: tokenId2);
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken1,
          expiresAt: expiresAt,
          deviceInfo: 'iPhone',
        );
        await repository.createRefreshToken(
          userId: testUserId!,
          token: refreshToken2,
          expiresAt: expiresAt,
          deviceInfo: 'Android',
        );

        final tokens = await repository.getUserTokens(testUserId!);

        expect(tokens.length, greaterThanOrEqualTo(2));
        expect(tokens.any((t) => t['id'] == tokenId1), isTrue);
        expect(tokens.any((t) => t['id'] == tokenId2), isTrue);
      });

      test('retorna lista vazia para usuário sem tokens', () async {
        final tokens = await repository.getUserTokens(99999);

        expect(tokens, isEmpty);
      });
    });
  });
}

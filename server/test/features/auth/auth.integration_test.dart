import 'package:test/test.dart';
import 'package:common/common.dart';
import 'package:server/features/auth/auth.controller.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/features/auth/refresh_token.repository.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';
import 'package:server/core/services/password_service.dart';
import 'package:server/core/services/jwt_service.dart';
import 'helpers/integration_test_db.dart';

void main() {
  group('Auth Integration Tests', () {
    late TestDBConnection dbConnection;
    late UserRepository userRepository;
    late RefreshTokenRepository refreshTokenRepository;
    late TokenBlacklistRepository blacklistRepository;
    late AuthController controller;

    setUpAll(() async {
      // Setup inicial: cria banco e executa migrations
      await IntegrationTestDB.setup();
    });

    setUp(() async {
      // Limpa dados antes de cada teste
      await IntegrationTestDB.cleanDatabase();

      // Cria conexão e repositories usando TestDBConnection
      dbConnection = TestDBConnection();
      userRepository = UserRepository(dbConnection as dynamic);
      refreshTokenRepository = RefreshTokenRepository(dbConnection as dynamic);
      blacklistRepository = TokenBlacklistRepository(dbConnection as dynamic);
      controller = AuthController(userRepository, refreshTokenRepository);
    });

    tearDown(() async {
      // Limpa dados após cada teste
      await IntegrationTestDB.cleanDatabase();
    });

    group('Login com Banco Real', () {
      test('deve fazer login e criar tokens no banco', () async {
        // Cria usuário diretamente no banco
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        // Faz login
        final result = await controller.login('teste@terafy.com', password);

        expect(result.user.id, user.id);
        expect(result.authToken, isNotEmpty);
        expect(result.refreshToken, isNotEmpty);

        // Verifica que refresh token foi salvo no banco
        final storedTokenId = await refreshTokenRepository.findTokenByHash(
          result.refreshToken,
        );
        expect(storedTokenId, isNotNull);

        // Verifica que lastLoginAt foi atualizado
        final updatedUser = await userRepository.getUserById(user.id!);
        expect(updatedUser?.lastLoginAt, isNotNull);
      });

      test('deve validar constraint de email único', () async {
        final passwordHash = PasswordService.hashPassword('senha123');
        
        await userRepository.createUser(
          User(
            email: 'duplicado@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        // Tenta criar outro usuário com mesmo email
        expect(
          () => userRepository.createUser(
            User(
              email: 'duplicado@terafy.com',
              passwordHash: passwordHash,
              role: 'therapist',
              status: 'active',
              emailVerified: false,
            ),
          ),
          throwsA(anything),
        );
      });

      test('deve validar constraint de account_type e account_id', () async {
        final passwordHash = PasswordService.hashPassword('senha123');

        // Tenta criar usuário com account_type mas sem account_id
        expect(
          () => userRepository.createUser(
            User(
              email: 'teste@terafy.com',
              passwordHash: passwordHash,
              role: 'therapist',
              accountType: 'therapist',
              accountId: null, // Deve falhar
              status: 'active',
              emailVerified: false,
            ),
          ),
          throwsA(anything),
        );
      });
    });

    group('Registro com Banco Real', () {
      test('deve criar usuário e tokens no banco', () async {
        final result = await controller.register('novo@terafy.com', 'senha123');

        expect(result.user.email, 'novo@terafy.com');
        expect(result.authToken, isNotEmpty);
        expect(result.refreshToken, isNotEmpty);

        // Verifica que usuário foi salvo no banco
        final savedUser = await userRepository.getUserByEmail('novo@terafy.com');
        expect(savedUser, isNotNull);
        expect(savedUser!.email, 'novo@terafy.com');

        // Verifica que refresh token foi salvo no banco
        final storedTokenId = await refreshTokenRepository.findTokenByHash(
          result.refreshToken,
        );
        expect(storedTokenId, isNotNull);
      });

      test('deve criar usuário sem accountType e accountId (permitido)', () async {
        final result = await controller.register('novo@terafy.com', 'senha123');

        expect(result.user.accountType, isNull);
        expect(result.user.accountId, isNull);

        // Verifica no banco
        final savedUser = await userRepository.getUserByEmail('novo@terafy.com');
        expect(savedUser?.accountType, isNull);
        expect(savedUser?.accountId, isNull);
      });
    });

    group('Refresh Token com Banco Real', () {
      test('deve renovar access token usando refresh token do banco', () async {
        // Cria usuário e faz login
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final loginResult = await controller.login('teste@terafy.com', password);
        final refreshToken = loginResult.refreshToken;

        // Renova access token
        final refreshResult = await controller.refreshAccessToken(refreshToken);

        expect(refreshResult['access_token'], isNotEmpty);
        expect(refreshResult['refresh_token'], refreshToken);

        // Valida novo access token
        final newAccessToken = refreshResult['access_token'] as String;
        final claims = JwtService.validateToken(newAccessToken);
        expect(claims, isNotNull);
        expect(claims!['sub'], user.id.toString());
      });

      test('deve falhar quando refresh token foi revogado no banco', () async {
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        
        await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final loginResult = await controller.login('teste@terafy.com', password);
        final refreshToken = loginResult.refreshToken;

        // Extrai tokenId do refresh token
        final claims = JwtService.decodeToken(refreshToken);
        final tokenId = claims?['jti'] as String?;
        expect(tokenId, isNotNull);

        // Revoga o token no banco
        await refreshTokenRepository.revokeToken(tokenId!);

        // Tenta renovar (deve falhar)
        expect(
          () => controller.refreshAccessToken(refreshToken),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('inválido'),
          )),
        );
      });
    });

    group('Logout com Banco Real', () {
      test('deve revogar refresh token e adicionar access token à blacklist', () async {
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        
        await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final loginResult = await controller.login('teste@terafy.com', password);
        final refreshToken = loginResult.refreshToken;
        final accessToken = loginResult.authToken;

        // Extrai JTI do access token
        final accessClaims = JwtService.decodeToken(accessToken);
        final accessTokenJti = accessClaims?['jti'] as String?;
        expect(accessTokenJti, isNotNull);

        // Faz logout
        await controller.revokeRefreshToken(
          refreshToken,
          accessToken: accessToken,
          blacklistRepository: blacklistRepository,
        );

        // Verifica que refresh token foi revogado
        final refreshClaims = JwtService.decodeToken(refreshToken);
        final refreshTokenId = refreshClaims?['jti'] as String?;
        if (refreshTokenId != null) {
          final storedTokenId = await refreshTokenRepository.findTokenByHash(
            refreshToken,
          );
          expect(storedTokenId, isNull);
        }

        // Verifica que access token está na blacklist
        final isBlacklisted = await blacklistRepository.isBlacklisted(
          accessTokenJti!,
        );
        expect(isBlacklisted, isTrue);
      });
    });

    group('Validações do Banco', () {
      test('deve validar ENUM de user_role', () async {
        final passwordHash = PasswordService.hashPassword('senha123');

        // Deve aceitar valores válidos
        await userRepository.createUser(
          User(
            email: 'therapist@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        await userRepository.createUser(
          User(
            email: 'patient@terafy.com',
            passwordHash: passwordHash,
            role: 'patient',
            status: 'active',
            emailVerified: false,
          ),
        );

        await userRepository.createUser(
          User(
            email: 'admin@terafy.com',
            passwordHash: passwordHash,
            role: 'admin',
            status: 'active',
            emailVerified: false,
          ),
        );

        // Todos devem ser criados com sucesso
        final therapist = await userRepository.getUserByEmail('therapist@terafy.com');
        final patient = await userRepository.getUserByEmail('patient@terafy.com');
        final admin = await userRepository.getUserByEmail('admin@terafy.com');

        expect(therapist?.role, 'therapist');
        expect(patient?.role, 'patient');
        expect(admin?.role, 'admin');
      });

      test('deve validar ENUM de account_status', () async {
        final passwordHash = PasswordService.hashPassword('senha123');

        await userRepository.createUser(
          User(
            email: 'active@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        await userRepository.createUser(
          User(
            email: 'suspended@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'suspended',
            emailVerified: false,
          ),
        );

        await userRepository.createUser(
          User(
            email: 'canceled@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'canceled',
            emailVerified: false,
          ),
        );

        final active = await userRepository.getUserByEmail('active@terafy.com');
        final suspended = await userRepository.getUserByEmail('suspended@terafy.com');
        final canceled = await userRepository.getUserByEmail('canceled@terafy.com');

        expect(active?.status, 'active');
        expect(suspended?.status, 'suspended');
        expect(canceled?.status, 'canceled');
      });
    });
  });
}


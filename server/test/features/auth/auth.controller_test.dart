import 'package:test/test.dart';
import 'package:common/common.dart';
import 'package:server/features/auth/auth.controller.dart';
import 'package:server/core/services/password_service.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:server/core/config/env_config.dart';
import 'helpers/test_auth_repositories.dart';

void main() {
  // Inicializa EnvConfig para garantir que JwtService funcione
  setUpAll(() {
    EnvConfig.load();
  });

  group('AuthController', () {
    late TestUserRepository userRepository;
    late TestRefreshTokenRepository refreshTokenRepository;
    late AuthController controller;

    setUp(() {
      userRepository = TestUserRepository();
      refreshTokenRepository = TestRefreshTokenRepository();
      controller = AuthController(userRepository, refreshTokenRepository);
    });

    tearDown(() {
      userRepository.clear();
      refreshTokenRepository.clear();
    });

    group('login', () {
      test('deve fazer login com credenciais válidas', () async {
        // Cria usuário de teste
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

        // Tenta fazer login
        final result = await controller.login('teste@terafy.com', password);

        expect(result.user.id, user.id);
        expect(result.user.email, 'teste@terafy.com');
        expect(result.authToken, isNotEmpty);
        expect(result.refreshToken, isNotEmpty);

        // Valida que os tokens são válidos
        final accessTokenClaims = JwtService.validateToken(result.authToken);
        expect(accessTokenClaims, isNotNull);
        expect(accessTokenClaims!['sub'], user.id.toString());
        expect(accessTokenClaims['email'], 'teste@terafy.com');
        expect(accessTokenClaims['role'], 'therapist');
        expect(accessTokenClaims['type'], 'access');

        final refreshTokenClaims = JwtService.validateToken(result.refreshToken);
        expect(refreshTokenClaims, isNotNull);
        expect(refreshTokenClaims!['type'], 'refresh');
      });

      test('deve lançar exceção quando email não existe', () async {
        expect(
          () => controller.login('naoexiste@terafy.com', 'senha123'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Credenciais inválidas',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('deve lançar exceção quando senha está incorreta', () async {
        final passwordHash = PasswordService.hashPassword('senha123');
        await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        expect(
          () => controller.login('teste@terafy.com', 'senha_errada'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Credenciais inválidas',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('deve lançar exceção quando conta está suspensa', () async {
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'suspended',
            emailVerified: false,
          ),
        );

        expect(
          () => controller.login('teste@terafy.com', password),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Conta suspensa ou cancelada',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            403,
          )),
        );
      });

      test('deve atualizar lastLoginAt após login bem-sucedido', () async {
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

        expect(user.lastLoginAt, isNull);

        await controller.login('teste@terafy.com', password);

        final updatedUser = await userRepository.getUserById(user.id!);
        expect(updatedUser?.lastLoginAt, isNotNull);
      });
    });

    group('register', () {
      test('deve registrar novo usuário com sucesso', () async {
        final result = await controller.register(
          'novo@terafy.com',
          'senha123',
        );

        expect(result.user.email, 'novo@terafy.com');
        expect(result.user.role, 'therapist');
        expect(result.user.status, 'active');
        expect(result.authToken, isNotEmpty);
        expect(result.refreshToken, isNotEmpty);
        expect(result.message, contains('sucesso'));

        // Verifica que o usuário foi criado
        final createdUser = await userRepository.getUserByEmail('novo@terafy.com');
        expect(createdUser, isNotNull);
        expect(createdUser!.email, 'novo@terafy.com');
      });

      test('deve lançar exceção quando senha é muito curta', () async {
        expect(
          () => controller.register('novo@terafy.com', '123'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Senha deve ter no mínimo 6 caracteres',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            400,
          )),
        );
      });

      test('deve lançar exceção quando email já existe', () async {
        await userRepository.createUser(
          User(
            email: 'existente@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        expect(
          () => controller.register('existente@terafy.com', 'senha123'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email já cadastrado',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            400,
          )),
        );
      });

      test('deve criar usuário sem accountType e accountId', () async {
        final result = await controller.register('novo@terafy.com', 'senha123');

        expect(result.user.accountType, isNull);
        expect(result.user.accountId, isNull);
      });
    });

    group('getCurrentUser', () {
      test('deve retornar usuário quando token é válido', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final token = JwtService.generateAccessToken(
          userId: user.id!,
          email: user.email,
          role: user.role,
        );

        final result = await controller.getCurrentUser(token);

        expect(result.id, user.id);
        expect(result.email, user.email);
        expect(result.role, user.role);
      });

      test('deve lançar exceção quando token é inválido', () async {
        expect(
          () => controller.getCurrentUser('token_invalido'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Token inválido ou expirado',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('deve lançar exceção quando usuário não existe', () async {
        final token = JwtService.generateAccessToken(
          userId: 99999,
          email: 'naoexiste@terafy.com',
          role: 'therapist',
        );

        expect(
          () => controller.getCurrentUser(token),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Usuário não encontrado',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            404,
          )),
        );
      });
    });

    group('refreshAccessToken', () {
      test('deve renovar access token com refresh token válido', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        // Cria refresh token
        final refreshTokenId = 'token_123';
        final refreshToken = JwtService.generateRefreshToken(
          userId: user.id!,
          tokenId: refreshTokenId,
        );

        // Simula armazenamento no repository
        await refreshTokenRepository.createRefreshToken(
          userId: user.id!,
          token: refreshToken,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final result = await controller.refreshAccessToken(refreshToken);

        expect(result['access_token'], isNotEmpty);
        expect(result['refresh_token'], refreshToken);

        // Valida novo access token
        final newAccessToken = result['access_token'] as String;
        final claims = JwtService.validateToken(newAccessToken);
        expect(claims, isNotNull);
        expect(claims!['sub'], user.id.toString());
        expect(claims['type'], 'access');
      });

      test('deve lançar exceção quando refresh token é inválido', () async {
        expect(
          () => controller.refreshAccessToken('token_invalido'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Refresh token inválido ou expirado',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('deve lançar exceção quando não é refresh token', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        // Usa access token em vez de refresh token
        final accessToken = JwtService.generateAccessToken(
          userId: user.id!,
          email: user.email,
          role: user.role,
        );

        expect(
          () => controller.refreshAccessToken(accessToken),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Token inválido. Use refresh token.',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('deve lançar exceção quando conta está suspensa', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'suspended',
            emailVerified: false,
          ),
        );

        final refreshTokenId = 'token_123';
        final refreshToken = JwtService.generateRefreshToken(
          userId: user.id!,
          tokenId: refreshTokenId,
        );

        await refreshTokenRepository.createRefreshToken(
          userId: user.id!,
          token: refreshToken,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(
          () => controller.refreshAccessToken(refreshToken),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Conta suspensa ou cancelada',
          ).having(
            (e) => e.statusCode,
            'statusCode',
            403,
          )),
        );
      });
    });

    group('revokeRefreshToken', () {
      test('deve revogar refresh token com sucesso', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final refreshTokenId = 'token_123';
        final refreshToken = JwtService.generateRefreshToken(
          userId: user.id!,
          tokenId: refreshTokenId,
        );

        await refreshTokenRepository.createRefreshToken(
          userId: user.id!,
          token: refreshToken,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final blacklistRepository = TestTokenBlacklistRepository();
        final accessToken = JwtService.generateAccessToken(
          userId: user.id!,
          email: user.email,
          role: user.role,
          jti: 'access_token_jti',
        );

        await controller.revokeRefreshToken(
          refreshToken,
          accessToken: accessToken,
          blacklistRepository: blacklistRepository,
        );

        // Verifica que refresh token foi revogado
        final tokenId = await refreshTokenRepository.findTokenByHash(refreshToken);
        expect(tokenId, isNull);

        // Verifica que access token foi adicionado à blacklist
        final isBlacklisted = await blacklistRepository.isBlacklisted('access_token_jti');
        expect(isBlacklisted, isTrue);
      });

      test('deve funcionar mesmo quando token é inválido', () async {
        final blacklistRepository = TestTokenBlacklistRepository();

        // Não deve lançar exceção mesmo com token inválido
        await controller.revokeRefreshToken(
          'token_invalido',
          blacklistRepository: blacklistRepository,
        );
      });
    });
  });
}


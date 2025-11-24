import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/entities/client.dart';
import 'package:terafy/core/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/login_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/logout_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/features/login/bloc/login_bloc.dart';
import 'package:terafy/features/login/bloc/login_bloc_models.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class _MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLoginUseCase loginUseCase;
  late _MockSignInWithGoogleUseCase signInWithGoogleUseCase;
  late _MockGetCurrentUserUseCase getCurrentUserUseCase;
  late _MockRefreshTokenUseCase refreshTokenUseCase;
  late _MockLogoutUseCase logoutUseCase;
  late _MockSecureStorageService secureStorageService;
  late _MockAuthService authService;

  final client = Client(
    id: '1',
    name: 'Terapeuta Teste',
    email: 'teste@terafy.com',
    accountId: 123,
  );

  final clientWithoutAccount = Client(
    id: '2',
    name: 'Terapeuta Incompleto',
    email: 'incompleto@terafy.com',
    accountId: null,
  );

  LoginBloc buildBloc() {
    return LoginBloc(
      loginUseCase: loginUseCase,
      signInWithGoogleUseCase: signInWithGoogleUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      refreshTokenUseCase: refreshTokenUseCase,
      logoutUseCase: logoutUseCase,
      secureStorageService: secureStorageService,
      authService: authService,
    );
  }

  setUp(() {
    loginUseCase = _MockLoginUseCase();
    signInWithGoogleUseCase = _MockSignInWithGoogleUseCase();
    getCurrentUserUseCase = _MockGetCurrentUserUseCase();
    refreshTokenUseCase = _MockRefreshTokenUseCase();
    logoutUseCase = _MockLogoutUseCase();
    secureStorageService = _MockSecureStorageService();
    authService = _MockAuthService();

    // Configurações padrão para mocks
    when(() => secureStorageService.getToken()).thenAnswer((_) async => null);
    when(
      () => secureStorageService.getRefreshToken(),
    ).thenAnswer((_) async => null);
    when(
      () => secureStorageService.getUserIdentifier(),
    ).thenAnswer((_) async => null);
    when(
      () => secureStorageService.saveToken(any()),
    ).thenAnswer((_) async => {});
    when(
      () => secureStorageService.saveRefreshToken(any()),
    ).thenAnswer((_) async => {});
    when(
      () => secureStorageService.saveUserIdentifier(any()),
    ).thenAnswer((_) async => {});
    when(() => secureStorageService.deleteToken()).thenAnswer((_) async => {});
    when(
      () => secureStorageService.deleteRefreshToken(),
    ).thenAnswer((_) async => {});
    when(
      () => secureStorageService.deleteUserIdentifier(),
    ).thenAnswer((_) async => {});

    when(() => authService.canCheckBiometrics()).thenAnswer((_) async => false);
    when(() => authService.authenticate()).thenAnswer((_) async => true);
  });

  group('LoginBloc - Seção 1.1: Login', () {
    test('inicial state é LoginInitial', () async {
      final bloc = buildBloc();
      // Aguarda o microtask inicial (CheckBiometricLogin) finalizar
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, equals(LoginInitial()));
      bloc.close();
    });

    blocTest<LoginBloc, LoginState>(
      '1.1.1 - Login com credenciais válidas - emite LoginSuccess',
      setUp: () {
        when(() => loginUseCase('teste@terafy.com', '123456')).thenAnswer(
          (_) async => AuthResult(
            authToken: 'access-token',
            refreshAuthToken: 'refresh-token',
            client: client,
          ),
        );
      },
      build: () {
        final bloc = buildBloc();
        // Aguarda o microtask inicial (CheckBiometricLogin) finalizar
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'teste@terafy.com',
          password: '123456',
          isBiometricsEnabled: false,
        ),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.client, 'client', equals(client))
            .having(
              (s) => s.requiresProfileCompletion,
              'requiresProfileCompletion',
              isFalse,
            ),
      ],
      verify: (_) {
        verify(() => loginUseCase('teste@terafy.com', '123456')).called(1);
        verify(() => secureStorageService.saveToken('access-token')).called(1);
        verify(
          () => secureStorageService.saveRefreshToken('refresh-token'),
        ).called(1);
        verifyNever(() => secureStorageService.saveUserIdentifier(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.1 - Login com credenciais válidas e biometria habilitada',
      setUp: () {
        when(() => loginUseCase('teste@terafy.com', '123456')).thenAnswer(
          (_) async => AuthResult(
            authToken: 'access-token',
            refreshAuthToken: 'refresh-token',
            client: client,
          ),
        );
        when(
          () => authService.canCheckBiometrics(),
        ).thenAnswer((_) async => true);
        when(() => authService.authenticate()).thenAnswer((_) async => true);
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'teste@terafy.com',
          password: '123456',
          isBiometricsEnabled: true,
        ),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.client, 'client', equals(client)),
      ],
      verify: (_) {
        verify(() => loginUseCase('teste@terafy.com', '123456')).called(1);
        verify(() => secureStorageService.saveToken('access-token')).called(1);
        verify(
          () => secureStorageService.saveRefreshToken('refresh-token'),
        ).called(1);
        verify(
          () => secureStorageService.saveUserIdentifier('teste@terafy.com'),
        ).called(1);
        // canCheckBiometrics pode ser chamado mais de uma vez (no CheckBiometricLogin inicial e no login)
        verify(
          () => authService.canCheckBiometrics(),
        ).called(greaterThanOrEqualTo(1));
        verify(() => authService.authenticate()).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.2 - Login com credenciais inválidas - emite LoginFailure',
      setUp: () {
        when(
          () => loginUseCase('invalid@test.com', 'wrongpassword'),
        ).thenAnswer(
          (_) async => const AuthResult(error: 'Credenciais inválidas'),
        );
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'invalid@test.com',
          password: 'wrongpassword',
          isBiometricsEnabled: false,
        ),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          equals('Credenciais inválidas'),
        ),
      ],
      verify: (_) {
        verify(
          () => loginUseCase('invalid@test.com', 'wrongpassword'),
        ).called(1);
        verifyNever(() => secureStorageService.saveToken(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.2 - Login com erro de exceção - emite LoginFailure',
      setUp: () {
        when(
          () => loginUseCase('teste@terafy.com', '123456'),
        ).thenThrow(Exception('Erro de conexão'));
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'teste@terafy.com',
          password: '123456',
          isBiometricsEnabled: false,
        ),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          contains('Erro de conexão'),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.1 - Login com perfil incompleto (accountId null) - requiresProfileCompletion true',
      setUp: () {
        when(() => loginUseCase('incompleto@terafy.com', '123456')).thenAnswer(
          (_) async => AuthResult(
            authToken: 'access-token',
            refreshAuthToken: 'refresh-token',
            client: clientWithoutAccount,
          ),
        );
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'incompleto@terafy.com',
          password: '123456',
          isBiometricsEnabled: false,
        ),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.client, 'client', equals(clientWithoutAccount))
            .having(
              (s) => s.requiresProfileCompletion,
              'requiresProfileCompletion',
              isTrue,
            ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.1 - Login sem refresh token - salva apenas access token',
      setUp: () {
        when(() => loginUseCase('teste@terafy.com', '123456')).thenAnswer(
          (_) async => AuthResult(authToken: 'access-token', client: client),
        );
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(
        const LoginButtonPressed(
          email: 'teste@terafy.com',
          password: '123456',
          isBiometricsEnabled: false,
        ),
      ),
      expect: () => [isA<LoginLoading>(), isA<LoginSuccess>()],
      verify: (_) {
        verify(() => secureStorageService.saveToken('access-token')).called(1);
        verifyNever(() => secureStorageService.saveRefreshToken(any()));
      },
    );
  });

  group('LoginBloc - Seção 1.1: Persistência de Sessão', () {
    blocTest<LoginBloc, LoginState>(
      '1.1.5 - Persistência de sessão - token válido ao reiniciar app',
      setUp: () {
        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => 'valid-token');
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');
        when(
          () => getCurrentUserUseCase(),
        ).thenAnswer((_) async => AuthResult(client: client));
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // CheckBiometricLogin é executado automaticamente no microtask
        // Como não há biometria configurada, CheckTokenValidity é chamado
        isA<LoginSuccess>().having((s) => s.client, 'client', equals(client)),
      ],
      verify: (_) {
        // getToken pode ser chamado mais de uma vez (CheckBiometricLogin e CheckTokenValidity)
        verify(
          () => secureStorageService.getToken(),
        ).called(greaterThanOrEqualTo(1));
        verify(() => getCurrentUserUseCase()).called(1);
        verifyNever(() => refreshTokenUseCase.call(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.5 - Persistência de sessão - token expirado, renova com refresh token',
      setUp: () {
        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => 'expired-token');
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');
        // Primeira chamada retorna erro (token expirado), segunda retorna sucesso após refresh
        var callCount = 0;
        when(() => getCurrentUserUseCase()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const AuthResult(error: 'Token expirado');
          }
          return AuthResult(client: client);
        });
        when(() => refreshTokenUseCase.call('refresh-token')).thenAnswer(
          (_) async => const AuthResult(
            authToken: 'new-access-token',
            refreshAuthToken: 'new-refresh-token',
          ),
        );
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<LoginSuccess>().having((s) => s.client, 'client', equals(client)),
      ],
      verify: (_) {
        verify(() => refreshTokenUseCase.call('refresh-token')).called(1);
        verify(
          () => secureStorageService.saveToken('new-access-token'),
        ).called(1);
        verify(
          () => secureStorageService.saveRefreshToken('new-refresh-token'),
        ).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.1.5 - Persistência de sessão - sem token, mantém LoginInitial',
      setUp: () {
        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => null);
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => null);
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // Deve permanecer em LoginInitial quando não há tokens
      ],
      verify: (_) {
        // getToken pode ser chamado mais de uma vez (CheckBiometricLogin)
        verify(
          () => secureStorageService.getToken(),
        ).called(greaterThanOrEqualTo(1));
        verifyNever(() => getCurrentUserUseCase());
      },
    );
  });

  group('LoginBloc - Seção 1.3: Logout', () {
    blocTest<LoginBloc, LoginState>(
      '1.3.1 - Logout funcional - limpa tokens e emite LogoutSuccess',
      setUp: () {
        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => 'access-token');
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');
        when(
          () => logoutUseCase.call(
            refreshToken: 'refresh-token',
            accessToken: 'access-token',
          ),
        ).thenAnswer((_) async => {});
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(LogoutPressed()),
      expect: () => [isA<LogoutSuccess>()],
      verify: (_) {
        verify(
          () => logoutUseCase.call(
            refreshToken: 'refresh-token',
            accessToken: 'access-token',
          ),
        ).called(1);
        // deleteToken pode ser chamado mais de uma vez (no CheckBiometricLogin inicial e no logout)
        verify(
          () => secureStorageService.deleteToken(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => secureStorageService.deleteRefreshToken(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => secureStorageService.deleteUserIdentifier(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<LoginBloc, LoginState>(
      '1.3.1 - Logout mesmo com erro no servidor - limpa tokens localmente',
      setUp: () {
        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => 'access-token');
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');
        when(
          () => logoutUseCase.call(
            refreshToken: 'refresh-token',
            accessToken: 'access-token',
          ),
        ).thenThrow(Exception('Erro de conexão'));
      },
      build: () {
        final bloc = buildBloc();
        return bloc;
      },
      wait: const Duration(milliseconds: 50),
      act: (bloc) => bloc.add(LogoutPressed()),
      expect: () => [isA<LogoutSuccess>()],
      verify: (_) {
        // Mesmo com erro, deve limpar tokens localmente
        // deleteToken pode ser chamado mais de uma vez (no CheckBiometricLogin inicial e no logout)
        verify(
          () => secureStorageService.deleteToken(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => secureStorageService.deleteRefreshToken(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => secureStorageService.deleteUserIdentifier(),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });
}

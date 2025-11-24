import 'dart:async';

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
    name: 'Therapist Test',
    email: 'therapist@example.com',
    accountId: 123,
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

  group('LoginBloc refresh flow', () {
    test('emits LoginSuccess when stored token is still valid', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      // Aguarda microtask inicial (CheckBiometricLogin) finalizar com stubs padrões.
      await Future<void>.delayed(Duration.zero);

      when(
        () => secureStorageService.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      when(
        () => secureStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(
        () => getCurrentUserUseCase(),
      ).thenAnswer((_) async => AuthResult(client: client));

      final collectedStates = <LoginState>[];
      final subscription = bloc.stream.listen(collectedStates.add);
      addTearDown(subscription.cancel);

      bloc.add(CheckTokenValidity());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(collectedStates.length, 1);
      final successState = collectedStates.first as LoginSuccess;
      expect(successState.client, equals(client));
      expect(successState.requiresProfileCompletion, isFalse);

      verify(() => getCurrentUserUseCase()).called(1);
      verifyNever(() => refreshTokenUseCase.call(any()));
    });

    test(
      'attempts refresh when token invalid and emits LoginSuccess after renewal',
      () async {
        final bloc = buildBloc();
        addTearDown(bloc.close);

        await Future<void>.delayed(Duration.zero);

        when(
          () => secureStorageService.getToken(),
        ).thenAnswer((_) async => 'expired-token');
        when(
          () => secureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');

        final responses = <AuthResult>[
          const AuthResult(error: 'invalid token'),
          AuthResult(client: client),
        ];

        when(
          () => getCurrentUserUseCase(),
        ).thenAnswer((_) async => responses.removeAt(0));

        when(() => refreshTokenUseCase.call('refresh-token')).thenAnswer(
          (_) async => const AuthResult(
            authToken: 'new-access-token',
            refreshAuthToken: 'new-refresh-token',
          ),
        );

        final collectedStates = <LoginState>[];
        final subscription = bloc.stream.listen(collectedStates.add);
        addTearDown(subscription.cancel);

        bloc.add(CheckTokenValidity());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(collectedStates.length, 1);
        final successState = collectedStates.first as LoginSuccess;
        expect(successState.client, equals(client));
        expect(successState.requiresProfileCompletion, isFalse);

        verify(() => refreshTokenUseCase.call('refresh-token')).called(1);
        verify(
          () => secureStorageService.saveToken('new-access-token'),
        ).called(1);
        verify(
          () => secureStorageService.saveRefreshToken('new-refresh-token'),
        ).called(1);
      },
    );

    test('cleans up tokens when refresh fails', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await Future<void>.delayed(Duration.zero);

      when(
        () => secureStorageService.getToken(),
      ).thenAnswer((_) async => 'expired-token');
      when(
        () => secureStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');

      when(
        () => getCurrentUserUseCase(),
      ).thenAnswer((_) async => const AuthResult(error: 'invalid token'));

      when(
        () => refreshTokenUseCase.call('refresh-token'),
      ).thenThrow(Exception('refresh failed'));

      final collectedStates = <LoginState>[];
      final subscription = bloc.stream.listen(collectedStates.add);
      addTearDown(subscription.cancel);

      bloc.add(CheckTokenValidity());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(collectedStates, isEmpty);

      verify(() => secureStorageService.deleteToken()).called(1);
      verify(() => secureStorageService.deleteRefreshToken()).called(1);
      verify(() => secureStorageService.deleteUserIdentifier()).called(1);
    });

    test('uses refresh token when access token is missing', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await Future<void>.delayed(Duration.zero);

      when(() => secureStorageService.getToken()).thenAnswer((_) async => null);
      when(
        () => secureStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');

      when(() => refreshTokenUseCase.call('refresh-token')).thenAnswer(
        (_) async => const AuthResult(
          authToken: 'new-access-token',
          refreshAuthToken: 'new-refresh-token',
        ),
      );

      when(
        () => getCurrentUserUseCase(),
      ).thenAnswer((_) async => AuthResult(client: client));

      final collectedStates = <LoginState>[];
      final subscription = bloc.stream.listen(collectedStates.add);
      addTearDown(subscription.cancel);

      bloc.add(CheckTokenValidity());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(collectedStates.length, 1);
      final successState = collectedStates.first as LoginSuccess;
      expect(successState.client, equals(client));
      expect(successState.requiresProfileCompletion, isFalse);

      verify(() => refreshTokenUseCase.call('refresh-token')).called(1);
    });
  });
}

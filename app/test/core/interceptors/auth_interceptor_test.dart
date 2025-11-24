import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/interceptors/auth_interceptor.dart';
import 'package:terafy/core/services/secure_storage_service.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

class _MockDio extends Mock implements Dio {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/fallback'));
  });

  group('AuthInterceptor', () {
    late _MockSecureStorageService secureStorage;
    late _MockRefreshTokenUseCase refreshTokenUseCase;
    late _MockDio dio;
    late AuthInterceptor interceptor;

    setUp(() {
      secureStorage = _MockSecureStorageService();
      refreshTokenUseCase = _MockRefreshTokenUseCase();
      dio = _MockDio();

      interceptor = AuthInterceptor(
        secureStorage,
        dio,
        refreshTokenUseCase: refreshTokenUseCase,
      );

      when(() => secureStorage.deleteToken()).thenAnswer((_) async {});
      when(() => secureStorage.deleteRefreshToken()).thenAnswer((_) async {});
      when(() => secureStorage.deleteUserIdentifier()).thenAnswer((_) async {});
    });

    test(
      'limpa estado de refresh quando refresh token está indisponível',
      () async {
        final requestOptions = RequestOptions(path: '/therapists');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(statusCode: 401, requestOptions: requestOptions),
          type: DioExceptionType.badResponse,
        );

        final handler = _MockErrorHandler();
        when(() => handler.reject(error)).thenAnswer((_) {});

        // Retorna null sempre para simular ausência de refresh token
        when(
          () => secureStorage.getRefreshToken(),
        ).thenAnswer((_) async => null);

        await Future.sync(() => interceptor.onError(error, handler));
        await Future.sync(() => interceptor.onError(error, handler));

        verify(() => secureStorage.deleteToken()).called(2);
        verify(() => secureStorage.deleteRefreshToken()).called(2);
        verify(() => secureStorage.deleteUserIdentifier()).called(2);
        verify(() => handler.reject(error)).called(2);
      },
    );

    test('rejeita requisições pendentes quando refresh falha', () async {
      final requestOptions = RequestOptions(path: '/therapists');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(statusCode: 401, requestOptions: requestOptions),
        type: DioExceptionType.badResponse,
      );

      final handler1 = _MockErrorHandler();
      final handler2 = _MockErrorHandler();

      when(() => handler1.reject(any())).thenAnswer((_) {});
      when(() => handler2.reject(any())).thenAnswer((_) {});

      when(
        () => secureStorage.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(
        () => refreshTokenUseCase.call('refresh-token'),
      ).thenThrow(Exception('refresh failed'));

      // Primeira requisição dispara o refresh
      interceptor.onError(error, handler1);

      // Segunda requisição chega enquanto o refresh está em andamento
      interceptor.onError(error, handler2);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => handler1.reject(any())).called(1);
      verify(() => handler2.reject(any())).called(1);
      verify(() => secureStorage.deleteToken()).called(1);
      verify(() => secureStorage.deleteRefreshToken()).called(1);
      verify(() => secureStorage.deleteUserIdentifier()).called(1);
    });
  });
}

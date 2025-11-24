import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/core/navigation/app_navigator.dart';
import 'package:common/common.dart';

/// Interceptor que adiciona automaticamente o token de autenticação
/// nas requisições e trata erros de token expirado com renovação automática
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  final RefreshTokenUseCase? _refreshTokenUseCase;
  final VoidCallback? onTokenExpired;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AuthInterceptor(
    this._secureStorage,
    this._dio, {
    RefreshTokenUseCase? refreshTokenUseCase,
    this.onTokenExpired,
  }) : _refreshTokenUseCase = refreshTokenUseCase;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.func();
    // Adiciona o token apenas se não for uma rota pública
    final publicRoutes = ['/auth/login', '/auth/register', '/auth/refresh'];
    final isPublicRoute = publicRoutes.any(
      (route) => options.path.contains(route),
    );

    if (!isPublicRoute) {
      final token = await _secureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    AppLogger.func();
    // Se o erro for 401 e não for login/refresh, tenta renovar o token
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != '/auth/login' &&
        err.requestOptions.path != '/auth/refresh') {
      // Se já está tentando refresh, adiciona à fila
      if (_isRefreshing) {
        AppLogger.info(
          '🔄 Refresh em andamento, adicionando requisição à fila',
        );
        _pendingRequests.add(
          _PendingRequest(options: err.requestOptions, handler: handler),
        );
        return;
      }

      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || _refreshTokenUseCase == null) {
        AppLogger.warning('⚠️ Refresh token ou use case indisponível');
        _rejectPending(err);
        await _logout();
        handler.reject(err);
        return;
      }

      // Tenta refresh
      _isRefreshing = true;
      AppLogger.info('🔄 Tentando renovar token automaticamente...');

      try {
        try {
          final result = await _refreshTokenUseCase.call(refreshToken);

          // Salva novos tokens
          if (result.authToken != null) {
            await _secureStorage.saveToken(result.authToken!);
            AppLogger.info('✅ Novo access token salvo');
          }
          if (result.refreshAuthToken != null) {
            await _secureStorage.saveRefreshToken(result.refreshAuthToken!);
            AppLogger.info('✅ Novo refresh token salvo');
          }

          // Atualiza header da requisição original
          err.requestOptions.headers['Authorization'] =
              'Bearer ${result.authToken}';

          // Retry da requisição original
          AppLogger.info('🔄 Retentando requisição original...');
          final response = await _dio.fetch(err.requestOptions);

          // Processa requisições pendentes
          _processPendingRequests(result.authToken!);

          handler.resolve(response);
          return;
        } catch (e) {
          AppLogger.warning('❌ Falha ao renovar token: $e');
          // Refresh falhou, fazer logout
          _rejectPending(err);
          await _logout();
          handler.reject(err);
          return;
        }
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }

  /// Processa requisições pendentes com o novo token
  void _processPendingRequests(String newToken) {
    AppLogger.func();
    AppLogger.info(
      '📋 Processando ${_pendingRequests.length} requisições pendentes',
    );

    for (var pending in _pendingRequests) {
      pending.options.headers['Authorization'] = 'Bearer $newToken';
      _dio
          .fetch(pending.options)
          .then(
            (response) {
              AppLogger.info('✅ Requisição pendente bem-sucedida');
              pending.handler.resolve(response);
            },
            onError: (error) {
              AppLogger.warning('❌ Requisição pendente falhou: $error');
              pending.handler.reject(error as DioException);
            },
          );
    }
    _pendingRequests.clear();
  }

  void _rejectPending(DioException error) {
    if (_pendingRequests.isEmpty) {
      return;
    }

    AppLogger.info(
      '❌ Cancelando ${_pendingRequests.length} requisições pendentes após falha de refresh',
    );

    for (var pending in _pendingRequests) {
      pending.handler.reject(error);
    }
    _pendingRequests.clear();
  }

  /// Faz logout limpando tokens e redirecionando para login
  Future<void> _logout() async {
    AppLogger.func();
    await _secureStorage.deleteToken();
    await _secureStorage.deleteRefreshToken();
    await _secureStorage.deleteUserIdentifier();

    // Chama callback se fornecido
    onTokenExpired?.call();

    // Redireciona para login
    if (navigatorKey.currentContext != null) {
      Navigator.of(
        navigatorKey.currentContext!,
      ).pushNamedAndRemoveUntil(AppRouter.loginRoute, (route) => false);
    }
  }
}

/// Classe auxiliar para armazenar requisições pendentes durante refresh
class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}

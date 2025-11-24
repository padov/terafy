import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdentifierKey = 'user_identifier';

  // Token temporário em memória (não persiste, usado apenas durante cadastro)
  String? _temporaryToken;
  String? _temporaryRefreshToken;

  // --- Token ---
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Salva token temporário em memória (não persiste no storage)
  /// Usado durante o fluxo de cadastro quando accountId ainda é null
  void saveTemporaryToken(String token) {
    _temporaryToken = token;
  }

  /// Salva refresh token temporário em memória
  void saveTemporaryRefreshToken(String token) {
    _temporaryRefreshToken = token;
  }

  /// Limpa tokens temporários
  void clearTemporaryTokens() {
    _temporaryToken = null;
    _temporaryRefreshToken = null;
  }

  Future<String?> getToken() async {
    // Primeiro verifica token temporário (em memória)
    if (_temporaryToken != null) {
      return _temporaryToken;
    }
    // Depois verifica token persistido
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    // Primeiro verifica refresh token temporário (em memória)
    if (_temporaryRefreshToken != null) {
      return _temporaryRefreshToken;
    }
    // Depois verifica refresh token persistido
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteToken() async {
    _temporaryToken = null; // Limpa token temporário também
    await _storage.delete(key: _tokenKey);
  }

  // --- Refresh Token ---
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> deleteRefreshToken() async {
    _temporaryRefreshToken = null; // Limpa refresh token temporário também
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- User Identifier (para saber qual usuário ativou a biometria) ---
  Future<void> saveUserIdentifier(String identifier) async {
    await _storage.write(key: _userIdentifierKey, value: identifier);
  }

  Future<String?> getUserIdentifier() async {
    return await _storage.read(key: _userIdentifierKey);
  }

  Future<void> deleteUserIdentifier() async {
    await _storage.delete(key: _userIdentifierKey);
  }

  // --- Limpar tudo (útil para testes e logout) ---
  Future<void> clearAll() async {
    clearTemporaryTokens();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdentifierKey);
  }
}

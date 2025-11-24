import 'package:terafy/core/data/models/client_model.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';

class AuthResultModel extends AuthResult {
  const AuthResultModel({
    super.authToken,
    super.refreshAuthToken,
    super.error,
    super.client,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    // Mapeia a resposta do backend para o formato esperado
    // Backend retorna: { "auth_token": "...", "refresh_token": "...", "user": {...} }
    final authToken = json['auth_token'] ?? json['authToken'];
    final refreshToken = json['refresh_token'] ?? json['refreshAuthToken'];
    final error = json['error'];

    // Converte o user do backend para Client
    ClientModel? client;
    if (json['user'] != null) {
      final userData = json['user'] as Map<String, dynamic>;
      // O backend retorna id como int, mas Client espera String
      final userId = userData['id'];
      final accountId = userData['account_id'];
      client = ClientModel(
        id: userId?.toString() ?? '',
        name:
            userData['email'] ??
            '', // Temporário - usar email como name até ter dados completos do terapeuta
        email: userData['email'] ?? '',
        accountId: accountId is int
            ? accountId
            : (accountId is String ? int.tryParse(accountId) : null),
      );
    } else if (json['client'] != null) {
      client = ClientModel.fromJson(json['client']);
    }

    return AuthResultModel(
      authToken: authToken,
      refreshAuthToken: refreshToken,
      error: error,
      client: client,
    );
  }
}

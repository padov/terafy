import 'package:equatable/equatable.dart';
import 'package:terafy/core/domain/entities/client.dart';

class AuthResult extends Equatable {
  final String? authToken;
  final String? refreshAuthToken;
  final String? error;
  final Client? client;

  const AuthResult({
    this.authToken,
    this.refreshAuthToken,
    this.error,
    this.client,
  });

  @override
  List<Object?> get props => [authToken, refreshAuthToken, error, client];
}

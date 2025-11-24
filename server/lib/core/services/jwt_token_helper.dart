import 'package:common/common.dart';
import 'jwt_service.dart';

/// Helper para trabalhar com tokens JWT usando o model JwtToken
class JwtTokenHelper {
  /// Valida e retorna um JwtToken a partir de uma string de token
  ///
  /// Retorna null se o token for inválido ou expirado
  static JwtToken? validateAndParse(String token) {
    final claims = JwtService.validateToken(token);
    if (claims == null) {
      return null;
    }

    try {
      return JwtToken.fromMap(claims);
    } catch (e) {
      return null;
    }
  }

  /// Decodifica um token sem validar (útil para debug)
  ///
  /// Retorna null se não conseguir decodificar
  static JwtToken? decode(String token) {
    final claims = JwtService.decodeToken(token);
    if (claims == null) {
      return null;
    }

    try {
      return JwtToken.fromMap(claims);
    } catch (e) {
      return null;
    }
  }
}

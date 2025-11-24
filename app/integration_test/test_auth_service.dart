import 'package:terafy/core/services/auth_service.dart';
import 'package:common/common.dart';

/// AuthService para testes de integração
/// Simula biometria sem solicitar interação real do usuário
class TestAuthService extends AuthService {
  bool _biometricsAvailable = true;
  bool _authenticateResult = true;

  /// Configura se a biometria está disponível
  void setBiometricsAvailable(bool available) {
    _biometricsAvailable = available;
  }

  /// Configura o resultado da autenticação biométrica
  void setAuthenticateResult(bool result) {
    _authenticateResult = result;
  }

  @override
  Future<bool> canCheckBiometrics() async {
    AppLogger.func();
    AppLogger.info('🧪 TestAuthService: canCheckBiometrics = $_biometricsAvailable');
    return _biometricsAvailable;
  }

  @override
  Future<bool> authenticate() async {
    AppLogger.func();
    AppLogger.info('🧪 TestAuthService: authenticate() - retornando $_authenticateResult (simulado)');
    // Simula um pequeno delay como se fosse uma autenticação real
    await Future.delayed(const Duration(milliseconds: 100));
    return _authenticateResult;
  }
}

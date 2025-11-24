import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:common/common.dart';

class AuthService {
  final local_auth.LocalAuthentication _auth = local_auth.LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    AppLogger.func();
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        return false;
      }
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      AppLogger.warning('Erro ao verificar biometria: $e');
      return false;
    } catch (e) {
      AppLogger.warning('Erro inesperado ao verificar biometria: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    AppLogger.func();
    AppLogger.info('🚀 ===== FUNÇÃO authenticate() CHAMADA! =====');
    AppLogger.info('🔐 Iniciando autenticação biométrica...');

    try {
      // Verifica se pode autenticar antes de tentar
      final canCheck = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();

      AppLogger.variable('canCheckBiometrics', canCheck.toString());
      AppLogger.variable('availableBiometrics', availableBiometrics.toString());

      if (!canCheck || availableBiometrics.isEmpty) {
        AppLogger.warning('⚠️ Biometria não disponível ou não configurada');
        return false;
      }

      AppLogger.info('📱 Solicitando autenticação biométrica ao usuário...');

      // Esta linha ABRE o diálogo de biometria no dispositivo
      // O usuário precisa colocar o dedo no sensor ou usar Face ID
      // biometricOnly: false permite fallback para PIN/Pattern se biometria falhar
      final result = await _auth.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar o app',
        biometricOnly: false, // Permite fallback para PIN/Pattern se necessário
      );

      AppLogger.variable('authenticate result', result.toString());

      if (result) {
        AppLogger.info('✅ Autenticação biométrica bem-sucedida!');
      } else {
        AppLogger.warning('❌ Autenticação biométrica falhou ou foi cancelada');
      }

      return result;
    } on local_auth.LocalAuthException catch (e) {
      AppLogger.error(e, StackTrace.current);
      AppLogger.variable('LocalAuthException code', e.code.toString());
      AppLogger.warning('❌ Erro LocalAuthException: ${e.code}');

      // Erro específico: Activity não é FragmentActivity
      if (e.code.toString() == 'uiUnavailable') {
        AppLogger.error(
          '⚠️ ERRO CRÍTICO: MainActivity precisa ser FlutterFragmentActivity!',
          StackTrace.current,
        );
        AppLogger.warning(
          '💡 Solução: Faça flutter clean e rebuild completo do app Android',
        );
      }

      return false;
    } on PlatformException catch (e) {
      AppLogger.error(e, StackTrace.current);
      AppLogger.variable('PlatformException code', e.code);
      AppLogger.variable('PlatformException message', e.message ?? 'null');
      AppLogger.warning(
        'Erro PlatformException na autenticação biométrica: ${e.code} - ${e.message}',
      );

      // Códigos de erro comuns do local_auth
      if (e.code == 'NotAvailable' ||
          e.code == 'NotEnrolled' ||
          e.code == 'LockedOut' ||
          e.code == 'PermanentlyLockedOut') {
        AppLogger.warning('⚠️ Erro específico: ${e.code}');
        return false;
      }
      // Para outros erros, também retorna false
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      AppLogger.variable('error', e.toString());
      AppLogger.warning('❌ Erro inesperado na autenticação: $e');
      return false;
    }
  }
}

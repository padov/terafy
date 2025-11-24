import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/auth/register_user_usecase.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:common/common.dart';
import 'simple_signup_bloc_models.dart';

class SimpleSignupBloc extends Bloc<SimpleSignupEvent, SimpleSignupState> {
  final RegisterUserUseCase registerUserUseCase;
  final SecureStorageService secureStorageService;

  SimpleSignupBloc({
    required this.registerUserUseCase,
    required this.secureStorageService,
  }) : super(SimpleSignupInitial()) {
    on<SimpleSignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
    SimpleSignupSubmitted event,
    Emitter<SimpleSignupState> emit,
  ) async {
    emit(SimpleSignupLoading());
    try {
      AppLogger.info('📝 Registrando novo usuário: ${event.email}');

      // Registra apenas o usuário (não cria terapeuta ainda)
      final authResult = await registerUserUseCase(event.email, event.password);

      if (authResult.error != null) {
        emit(SimpleSignupFailure(error: authResult.error!));
        return;
      }

      final authToken = authResult.authToken;
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Não foi possível obter o token de autenticação.');
      }

      // Salva o token temporariamente em memória (não persiste no storage)
      // Isso permite fazer requisições durante o cadastro sem salvar token sem accountId
      // O token será salvo no storage apenas após completar o perfil
      secureStorageService.saveTemporaryToken(authToken);
      if (authResult.refreshAuthToken != null) {
        secureStorageService.saveTemporaryRefreshToken(
          authResult.refreshAuthToken!,
        );
      }

      AppLogger.info(
        '✅ Usuário registrado com sucesso! Token salvo temporariamente em memória (não persiste).',
      );
      emit(SimpleSignupSuccess(authToken: authToken));
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      emit(SimpleSignupFailure(error: _mapErrorMessage(e)));
    }
  }

  String _mapErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}

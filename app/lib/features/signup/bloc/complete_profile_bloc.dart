import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/entities/therapist_signup_input.dart';
import 'package:terafy/core/domain/usecases/therapist/create_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:common/common.dart';

import 'complete_profile_bloc_models.dart';

class CompleteProfileBloc
    extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final CreateTherapistUseCase createTherapistUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final SecureStorageService secureStorageService;

  CompleteProfileBloc({
    required this.createTherapistUseCase,
    required this.getCurrentUserUseCase,
    required this.refreshTokenUseCase,
    required this.secureStorageService,
  }) : super(const CompleteProfileInitial()) {
    on<NextStepPressed>(_onNextStepPressed);
    on<PreviousStepPressed>(_onPreviousStepPressed);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdateProfessionalData>(_onUpdateProfessionalData);
    on<SubmitCompleteProfile>(_onSubmitCompleteProfile);
    on<LoadCurrentUserEmail>(_onLoadCurrentUserEmail);

    // Carrega email do usuário atual ao iniciar
    add(const LoadCurrentUserEmail());
  }

  Future<void> _onLoadCurrentUserEmail(
    LoadCurrentUserEmail event,
    Emitter<CompleteProfileState> emit,
  ) async {
    try {
      final authResult = await getCurrentUserUseCase();
      if (authResult.client != null) {
        final email = authResult.client!.email;
        // Atualiza apenas o email, preservando outros dados
        final updatedData = state.data.copyWith(email: email);
        emit(
          CompleteProfileInProgress(
            currentStep: state.currentStep,
            data: updatedData,
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('Não foi possível carregar email do usuário: $e');
      // Não emite erro, apenas loga - permite que o usuário continue mesmo sem email pré-carregado
    }
  }

  void _onNextStepPressed(
    NextStepPressed event,
    Emitter<CompleteProfileState> emit,
  ) {
    // Agora só temos 2 steps (0 e 1), então limite máximo é 1
    if (state.currentStep < 1) {
      emit(
        CompleteProfileInProgress(
          currentStep: state.currentStep + 1,
          data: state.data,
        ),
      );
    }
  }

  void _onPreviousStepPressed(
    PreviousStepPressed event,
    Emitter<CompleteProfileState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(
        CompleteProfileInProgress(
          currentStep: state.currentStep - 1,
          data: state.data,
        ),
      );
    }
  }

  void _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<CompleteProfileState> emit,
  ) {
    final updatedData = state.data.copyWith(
      name: event.name,
      nickname: event.nickname,
      legalDocument: event.legalDocument,
      email: event.email,
      phone: event.phone,
      birthday: event.birthday,
    );

    emit(
      CompleteProfileInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateProfessionalData(
    UpdateProfessionalData event,
    Emitter<CompleteProfileState> emit,
  ) {
    final updatedData = state.data.copyWith(
      specialties: event.specialties,
      professionalRegistrations: event.professionalRegistrations,
      presentation: event.presentation,
      address: event.address,
    );

    emit(
      CompleteProfileInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  Future<void> _onSubmitCompleteProfile(
    SubmitCompleteProfile event,
    Emitter<CompleteProfileState> emit,
  ) async {
    AppLogger.func();
    final data = state.data;

    // Validações (planId não é mais obrigatório)
    if ((data.name ?? '').trim().isEmpty ||
        (data.email ?? '').trim().isEmpty ||
        (data.legalDocument ?? '').trim().isEmpty) {
      emit(
        CompleteProfileFailure(
          currentStep: state.currentStep,
          data: state.data,
          error: 'Preencha todos os dados obrigatórios antes de continuar.',
        ),
      );
      return;
    }

    emit(
      CompleteProfileLoading(currentStep: state.currentStep, data: state.data),
    );

    try {
      // Prepara dados do terapeuta
      final registry = _extractProfessionalRegistry(
        data.professionalRegistrations,
      );

      final specialties = data.specialties
          ?.map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
      final presentation = (data.presentation?.trim().isNotEmpty ?? false)
          ? data.presentation!.trim()
          : null;
      final address = (data.address?.trim().isNotEmpty ?? false)
          ? data.address!.trim()
          : null;

      final therapistInput = TherapistSignupInput(
        name: data.name!.trim(),
        nickname: data.nickname?.trim().isEmpty ?? true ? null : data.nickname!.trim(),
        document: data.legalDocument?.trim(),
        email: data.email!.trim(),
        phone: data.phone?.trim(),
        birthDate: data.birthday,
        professionalRegistryType: registry.type,
        professionalRegistryNumber: registry.number,
        specialties: (specialties?.isEmpty ?? true) ? null : specialties,
        professionalPresentation: presentation,
        officeAddress: address,
        planId: null, // Plano não é mais selecionado no cadastro
      );

      // Cria o cadastro do terapeuta
      await createTherapistUseCase(input: therapistInput);

      // Recarrega os dados do usuário para obter o accountId atualizado
      // O backend atualiza o accountId após criar o terapeuta
      final authResult = await getCurrentUserUseCase();
      final updatedClient = authResult.client;

      AppLogger.info('✅ Perfil completado com sucesso!');
      AppLogger.variable(
        'accountId após criar terapeuta',
        updatedClient?.accountId?.toString() ?? 'null',
      );

      // Verifica se o accountId foi atualizado
      if (updatedClient?.accountId == null) {
        throw Exception(
          'Erro: accountId não foi atualizado após criar o terapeuta. '
          'Tente fazer login novamente.',
        );
      }

      // Faz refresh do token para obter um novo token com accountId atualizado
      // O token temporário não tinha accountId, então precisamos de um novo token
      try {
        final refreshToken = await secureStorageService.getRefreshToken();
        if (refreshToken != null) {
          AppLogger.info(
            '🔄 Fazendo refresh do token para atualizar accountId...',
          );
          final refreshResult = await refreshTokenUseCase.call(refreshToken);

          if (refreshResult.authToken != null) {
            // Agora que o perfil está completo (accountId != null), salva no storage
            await secureStorageService.saveToken(refreshResult.authToken!);
            AppLogger.info(
              '✅ Novo token salvo no storage com accountId atualizado',
            );

            if (refreshResult.refreshAuthToken != null) {
              await secureStorageService.saveRefreshToken(
                refreshResult.refreshAuthToken!,
              );
            }

            // Limpa tokens temporários (não são mais necessários)
            secureStorageService.clearTemporaryTokens();
          } else {
            AppLogger.warning(
              '⚠️ Não foi possível obter novo token após refresh',
            );
          }
        } else {
          AppLogger.warning(
            '⚠️ Refresh token não encontrado. Token não será atualizado.',
          );
        }
      } catch (e) {
        AppLogger.warning('⚠️ Erro ao fazer refresh do token: $e');
        // Não falha o cadastro por causa disso, mas loga o erro
      }

      emit(
        CompleteProfileSuccess(
          currentStep: state.currentStep,
          data: state.data,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);

      emit(
        CompleteProfileFailure(
          currentStep: state.currentStep,
          data: state.data,
          error: _mapErrorMessage(e),
        ),
      );
    }
  }

  _RegistryInfo _extractProfessionalRegistry(List<String>? registrations) {
    if (registrations == null || registrations.isEmpty) {
      return const _RegistryInfo();
    }

    final first = registrations.first.trim();
    if (first.isEmpty) {
      return const _RegistryInfo();
    }

    final parts = first.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _RegistryInfo(number: parts.first);
    }

    final type = parts.first.toUpperCase();
    final number = parts.sublist(1).join(' ');
    return _RegistryInfo(type: type, number: number);
  }

  String _mapErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}

class _RegistryInfo {
  final String? type;
  final String? number;

  const _RegistryInfo({this.type, this.number});
}

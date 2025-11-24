import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/entities/therapist_signup_input.dart';
import 'package:terafy/core/domain/usecases/auth/register_user_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/create_therapist_usecase.dart';
import 'package:common/common.dart';

import 'signup_bloc_models.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final RegisterUserUseCase registerUserUseCase;
  final CreateTherapistUseCase createTherapistUseCase;

  SignupBloc({
    required this.registerUserUseCase,
    required this.createTherapistUseCase,
  }) : super(const SignupInitial()) {
    on<NextStepPressed>(_onNextStepPressed);
    on<PreviousStepPressed>(_onPreviousStepPressed);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdateProfessionalData>(_onUpdateProfessionalData);
    on<SelectPlan>(_onSelectPlan);
    on<SubmitSignup>(_onSubmitSignup);
  }

  void _onNextStepPressed(NextStepPressed event, Emitter<SignupState> emit) {
    if (state.currentStep < 2) {
      emit(
        SignupInProgress(currentStep: state.currentStep + 1, data: state.data),
      );
    }
  }

  void _onPreviousStepPressed(
    PreviousStepPressed event,
    Emitter<SignupState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(
        SignupInProgress(currentStep: state.currentStep - 1, data: state.data),
      );
    }
  }

  void _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<SignupState> emit,
  ) {
    final updatedData = state.data.copyWith(
      name: event.name,
      nickname: event.nickname,
      legalDocument: event.legalDocument,
      email: event.email,
      phone: event.phone,
      birthday: event.birthday,
      password:
          event.password ??
          state.data.password, // Mantém senha existente se não fornecida
    );

    emit(SignupInProgress(currentStep: state.currentStep, data: updatedData));
  }

  void _onUpdateProfessionalData(
    UpdateProfessionalData event,
    Emitter<SignupState> emit,
  ) {
    final updatedData = state.data.copyWith(
      specialties: event.specialties,
      professionalRegistrations: event.professionalRegistrations,
      presentation: event.presentation,
      address: event.address,
    );

    emit(SignupInProgress(currentStep: state.currentStep, data: updatedData));
  }

  void _onSelectPlan(SelectPlan event, Emitter<SignupState> emit) {
    final updatedData = state.data.copyWith(planId: event.planId);

    emit(SignupInProgress(currentStep: state.currentStep, data: updatedData));
  }

  Future<void> _onSubmitSignup(
    SubmitSignup event,
    Emitter<SignupState> emit,
  ) async {
    final data = state.data;

    if ((data.name ?? '').trim().isEmpty ||
        (data.email ?? '').trim().isEmpty ||
        (data.password?.isEmpty ?? true) ||
        (data.legalDocument ?? '').trim().isEmpty ||
        data.planId == null) {
      emit(
        SignupFailure(
          currentStep: state.currentStep,
          data: state.data,
          error: 'Preencha todos os dados obrigatórios antes de continuar.',
        ),
      );
      return;
    }

    emit(SignupLoading(currentStep: state.currentStep, data: state.data));

    try {
      // 1. Registra o usuário e obtém o token de autenticação
      final password = data.password;
      if (password == null || password.isEmpty) {
        throw Exception('Senha é obrigatória para criar a conta.');
      }

      final authResult = await registerUserUseCase(
        data.email!.trim(),
        password,
      );

      final authToken = authResult.authToken;
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Não foi possível obter o token de autenticação.');
      }

      // 2. Prepara dados do terapeuta
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
        planId: data.planId,
      );

      // 3. Cria o cadastro do terapeuta
      await createTherapistUseCase(input: therapistInput);

      emit(SignupSuccess(currentStep: state.currentStep, data: state.data));
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);

      emit(
        SignupFailure(
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

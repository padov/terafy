import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/update_therapist_usecase.dart';
import 'package:common/common.dart';

import 'edit_profile_bloc_models.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final GetCurrentTherapistUseCase getCurrentTherapistUseCase;
  final UpdateTherapistUseCase updateTherapistUseCase;

  EditProfileBloc({
    required this.getCurrentTherapistUseCase,
    required this.updateTherapistUseCase,
  }) : super(const EditProfileInitial()) {
    on<LoadProfileData>(_onLoadProfileData);
    on<NextStepPressed>(_onNextStepPressed);
    on<PreviousStepPressed>(_onPreviousStepPressed);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdateProfessionalData>(_onUpdateProfessionalData);
    on<SubmitEditProfile>(_onSubmitEditProfile);

    // Carrega dados do perfil ao iniciar
    add(const LoadProfileData());
  }

  Future<void> _onLoadProfileData(
    LoadProfileData event,
    Emitter<EditProfileState> emit,
  ) async {
    AppLogger.func();
    emit(const EditProfileLoading(currentStep: 0, data: EditProfileData()));

    try {
      final therapistData = await getCurrentTherapistUseCase();
      final therapist = Therapist.fromMap(therapistData);

      // Extrai o registro profissional
      String? registryType = therapist.professionalRegistryType;
      String? registryNumber = therapist.professionalRegistryNumber;
      List<String> professionalRegistrations = [];
      
      if (registryType != null && registryNumber != null) {
        professionalRegistrations = ['$registryType $registryNumber'];
      } else if (registryNumber != null) {
        professionalRegistrations = [registryNumber];
      }

      final data = EditProfileData(
        name: therapist.name,
        nickname: therapist.nickname,
        legalDocument: therapist.document,
        email: therapist.email,
        phone: therapist.phone,
        birthday: therapist.birthDate,
        specialties: therapist.specialties,
        professionalRegistrations: professionalRegistrations.isNotEmpty 
            ? professionalRegistrations 
            : null,
        presentation: therapist.professionalPresentation,
        address: therapist.officeAddress,
      );

      emit(EditProfileLoaded(currentStep: 0, data: data));
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      emit(
        EditProfileFailure(
          currentStep: 0,
          data: const EditProfileData(),
          error: _mapErrorMessage(e),
        ),
      );
    }
  }

  void _onNextStepPressed(
    NextStepPressed event,
    Emitter<EditProfileState> emit,
  ) {
    if (state.currentStep < 1) {
      emit(
        EditProfileInProgress(
          currentStep: state.currentStep + 1,
          data: state.data,
        ),
      );
    }
  }

  void _onPreviousStepPressed(
    PreviousStepPressed event,
    Emitter<EditProfileState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(
        EditProfileInProgress(
          currentStep: state.currentStep - 1,
          data: state.data,
        ),
      );
    }
  }

  void _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<EditProfileState> emit,
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
      EditProfileInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateProfessionalData(
    UpdateProfessionalData event,
    Emitter<EditProfileState> emit,
  ) {
    final updatedData = state.data.copyWith(
      specialties: event.specialties,
      professionalRegistrations: event.professionalRegistrations,
      presentation: event.presentation,
      address: event.address,
    );

    emit(
      EditProfileInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  Future<void> _onSubmitEditProfile(
    SubmitEditProfile event,
    Emitter<EditProfileState> emit,
  ) async {
    AppLogger.func();
    final data = state.data;

    // Validações básicas
    if ((data.name ?? '').trim().isEmpty ||
        (data.email ?? '').trim().isEmpty) {
      emit(
        EditProfileFailure(
          currentStep: state.currentStep,
          data: state.data,
          error: 'Preencha todos os dados obrigatórios antes de continuar.',
        ),
      );
      return;
    }

    emit(
      EditProfileSaving(currentStep: state.currentStep, data: state.data),
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

      final therapist = Therapist(
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
        status: 'active', // Mantém status ativo
      );

      // Atualiza o perfil do terapeuta
      await updateTherapistUseCase(therapist: therapist);

      AppLogger.info('✅ Perfil atualizado com sucesso!');

      emit(
        EditProfileSuccess(
          currentStep: state.currentStep,
          data: state.data,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);

      emit(
        EditProfileFailure(
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

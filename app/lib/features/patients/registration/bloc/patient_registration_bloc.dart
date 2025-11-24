import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class PatientRegistrationBloc
    extends Bloc<PatientRegistrationEvent, PatientRegistrationState> {
  static const int totalSteps = 6;

  PatientRegistrationBloc() : super(PatientRegistrationInitial()) {
    on<UpdateIdentificationData>(_onUpdateIdentificationData);
    on<UpdateContactData>(_onUpdateContactData);
    on<UpdateProfessionalSocialData>(_onUpdateProfessionalSocialData);
    on<UpdateHealthData>(_onUpdateHealthData);
    on<UpdateAnamnesisData>(_onUpdateAnamnesisData);
    on<UpdateAdministrativeData>(_onUpdateAdministrativeData);
    on<NextStepPressed>(_onNextStepPressed);
    on<PreviousStepPressed>(_onPreviousStepPressed);
    on<SavePatientPressed>(_onSavePatientPressed);
  }

  void _onUpdateIdentificationData(
    UpdateIdentificationData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(identification: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateContactData(
    UpdateContactData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(contact: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateProfessionalSocialData(
    UpdateProfessionalSocialData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(professionalSocial: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateHealthData(
    UpdateHealthData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(health: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateAnamnesisData(
    UpdateAnamnesisData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(anamnesis: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onUpdateAdministrativeData(
    UpdateAdministrativeData event,
    Emitter<PatientRegistrationState> emit,
  ) {
    final updatedData = state.data.copyWith(administrative: event.data);
    emit(
      PatientRegistrationInProgress(
        currentStep: state.currentStep,
        data: updatedData,
      ),
    );
  }

  void _onNextStepPressed(
    NextStepPressed event,
    Emitter<PatientRegistrationState> emit,
  ) {
    if (state.currentStep < totalSteps - 1) {
      emit(
        PatientRegistrationInProgress(
          currentStep: state.currentStep + 1,
          data: state.data,
        ),
      );
    }
  }

  void _onPreviousStepPressed(
    PreviousStepPressed event,
    Emitter<PatientRegistrationState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(
        PatientRegistrationInProgress(
          currentStep: state.currentStep - 1,
          data: state.data,
        ),
      );
    }
  }

  Future<void> _onSavePatientPressed(
    SavePatientPressed event,
    Emitter<PatientRegistrationState> emit,
  ) async {
    emit(
      PatientRegistrationLoading(
        currentStep: state.currentStep,
        data: state.data,
      ),
    );

    try {
      // Validações básicas
      if (state.data.identification == null) {
        emit(
          PatientRegistrationError(
            message: 'Dados de identificação são obrigatórios',
            currentStep: state.currentStep,
            data: state.data,
          ),
        );
        return;
      }

      if (state.data.contact == null) {
        emit(
          PatientRegistrationError(
            message: 'Dados de contato são obrigatórios',
            currentStep: state.currentStep,
            data: state.data,
          ),
        );
        return;
      }

      // Simular salvamento
      await Future.delayed(const Duration(seconds: 1));

      // Converter para Patient e emitir sucesso
      final patient = state.data.toPatient();

      emit(
        PatientRegistrationSuccess(
          patient: patient,
          currentStep: state.currentStep,
          data: state.data,
        ),
      );
    } catch (e) {
      emit(
        PatientRegistrationError(
          message: 'Erro ao salvar paciente: $e',
          currentStep: state.currentStep,
          data: state.data,
        ),
      );
    }
  }

  bool canProceedToNextStep() {
    switch (state.currentStep) {
      case 0: // Identificação
        return state.data.identification != null &&
            state.data.identification!.fullName.isNotEmpty;
      case 1: // Contato
        return state.data.contact != null &&
            state.data.contact!.phone.isNotEmpty;
      case 2: // Profissional/Social
        return true; // Opcional
      case 3: // Saúde
        return true; // Opcional
      case 4: // Anamnese
        return true; // Opcional
      case 5: // Administrativo
        return true; // Opcional
      default:
        return false;
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/domain/usecases/patient/create_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/update_patient_usecase.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class PatientRegistrationBloc
    extends Bloc<PatientRegistrationEvent, PatientRegistrationState> {
  static const int totalSteps = 5;

  final Patient? patientToEdit;
  final CreatePatientUseCase? _createPatientUseCase;
  final UpdatePatientUseCase? _updatePatientUseCase;

  PatientRegistrationBloc({this.patientToEdit})
      : _createPatientUseCase = patientToEdit == null
            ? DependencyContainer().createPatientUseCase
            : null,
        _updatePatientUseCase = patientToEdit != null
            ? DependencyContainer().updatePatientUseCase
            : null,
        super(patientToEdit != null
            ? PatientRegistrationInProgress(
                currentStep: 0,
                data: _createInitialDataFromPatient(patientToEdit),
              )
            : PatientRegistrationInitial()) {
    on<UpdateIdentificationData>(_onUpdateIdentificationData);
    on<UpdateContactData>(_onUpdateContactData);
    on<UpdateProfessionalSocialData>(_onUpdateProfessionalSocialData);
    on<UpdateHealthData>(_onUpdateHealthData);
    on<UpdateAdministrativeData>(_onUpdateAdministrativeData);
    on<NextStepPressed>(_onNextStepPressed);
    on<PreviousStepPressed>(_onPreviousStepPressed);
    on<SavePatientPressed>(_onSavePatientPressed);
  }

  static PatientRegistrationData _createInitialDataFromPatient(Patient patient) {
    return PatientRegistrationData(
      identification: IdentificationData(
        fullName: patient.fullName,
        cpf: patient.cpf,
        rg: patient.rg,
        dateOfBirth: patient.dateOfBirth,
        gender: patient.gender,
        maritalStatus: patient.maritalStatus,
        photoUrl: patient.photoUrl,
      ),
      contact: ContactData(
        phone: patient.phone,
        email: patient.email,
        address: patient.address,
        emergencyContact: patient.emergencyContact,
        legalGuardian: patient.legalGuardian,
      ),
      professionalSocial: ProfessionalSocialData(
        profession: patient.profession,
        education: patient.education,
      ),
      health: HealthData(
        healthInsurance: patient.healthInsurance,
        insuranceNumber: patient.insuranceCardNumber,
      ),
      administrative: AdministrativeData(
        sessionValue: patient.sessionValue,
        paymentMethod: patient.preferredPaymentMethod,
        consentDate: patient.consentDate,
        lgpdAcceptanceDate: patient.lgpdAcceptDate,
        tags: patient.tags,
        generalObservations: patient.notes,
        agendaColor: patient.agendaColor,
      ),
    );
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

      // Converter para Patient
      final patient = state.data.toPatient(patientToEdit: patientToEdit);

      // Salvar ou atualizar
      Patient savedPatient;
      if (patientToEdit != null) {
        // Modo edição - atualizar
        final updateUseCase = _updatePatientUseCase;
        if (updateUseCase == null) {
          throw Exception('UpdatePatientUseCase não disponível');
        }
        savedPatient = await updateUseCase(patient: patient);
      } else {
        // Modo criação - criar novo
        final createUseCase = _createPatientUseCase;
        if (createUseCase == null) {
          throw Exception('CreatePatientUseCase não disponível');
        }
        savedPatient = await createUseCase(
          fullName: patient.fullName,
          phone: patient.phone,
          email: patient.email,
          birthDate: patient.dateOfBirth,
        );
        // TODO: Atualizar outros campos após criação inicial
        // Por enquanto, apenas os campos básicos são salvos na criação rápida
      }

      emit(
        PatientRegistrationSuccess(
          patient: savedPatient,
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
      case 4: // Administrativo
        return true; // Opcional
      default:
        return false;
    }
  }
}

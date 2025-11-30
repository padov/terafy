import 'package:equatable/equatable.dart';
import 'package:terafy/features/patients/models/patient.dart';

// Events
abstract class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatients extends PatientsEvent {
  const LoadPatients();
}

class RefreshPatients extends PatientsEvent {
  const RefreshPatients();
}

class SearchPatients extends PatientsEvent {
  final String query;

  const SearchPatients(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterPatientsByStatus extends PatientsEvent {
  final PatientStatus? status;

  const FilterPatientsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class AddQuickPatient extends PatientsEvent {
  final String fullName;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;

  const AddQuickPatient({required this.fullName, required this.phone, this.email, this.dateOfBirth});

  @override
  List<Object?> get props => [fullName, phone, email, dateOfBirth];
}

class SelectPatient extends PatientsEvent {
  final String patientId;

  const SelectPatient(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class RequestAIAnalysis extends PatientsEvent {
  final String patientId;

  const RequestAIAnalysis(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class ResetPatientsView extends PatientsEvent {
  const ResetPatientsView();
}

class UpdatePatient extends PatientsEvent {
  final Patient patient;

  const UpdatePatient(this.patient);

  @override
  List<Object?> get props => [patient];
}

class UpdatePatientNotes extends PatientsEvent {
  final String patientId;
  final String? notes;

  const UpdatePatientNotes({required this.patientId, this.notes});

  @override
  List<Object?> get props => [patientId, notes];
}

// States
abstract class PatientsState extends Equatable {
  const PatientsState();

  @override
  List<Object?> get props => [];
}

class PatientsInitial extends PatientsState {
  const PatientsInitial();
}

class PatientsLoading extends PatientsState {
  const PatientsLoading();
}

class PatientsLoaded extends PatientsState {
  final List<Patient> patients;
  final List<Patient> filteredPatients;
  final String? searchQuery;
  final PatientStatus? statusFilter;
  final int? patientCount;
  final int? patientLimit;
  final bool? canCreatePatient;

  const PatientsLoaded({
    required this.patients,
    required this.filteredPatients,
    this.searchQuery,
    this.statusFilter,
    this.patientCount,
    this.patientLimit,
    this.canCreatePatient,
  });

  int get usagePercentage {
    if (patientLimit == null || patientLimit == 0) return 0;
    final limit = patientLimit!;
    final count = patientCount ?? 0;
    return ((count / limit) * 100).round();
  }

  bool get isNearLimit => usagePercentage >= 80;
  bool get isAtLimit => usagePercentage >= 100;

  @override
  List<Object?> get props => [
    patients,
    filteredPatients,
    searchQuery,
    statusFilter,
    patientCount,
    patientLimit,
    canCreatePatient,
  ];
}

class PatientSelected extends PatientsState {
  final Patient patient;

  const PatientSelected(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientAdding extends PatientsState {
  const PatientAdding();
}

class PatientAdded extends PatientsState {
  final Patient patient;

  const PatientAdded(this.patient);

  @override
  List<Object?> get props => [patient];
}

class AIAnalysisLoading extends PatientsState {
  final Patient patient;

  const AIAnalysisLoading(this.patient);

  @override
  List<Object?> get props => [patient];
}

class AIAnalysisLoaded extends PatientsState {
  final Patient patient;
  final String analysis;

  const AIAnalysisLoaded({required this.patient, required this.analysis});

  @override
  List<Object?> get props => [patient, analysis];
}

class PatientsError extends PatientsState {
  final String message;

  const PatientsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PatientUpdating extends PatientsState {
  final Patient patient;

  const PatientUpdating(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientUpdated extends PatientsState {
  final Patient patient;

  const PatientUpdated(this.patient);

  @override
  List<Object?> get props => [patient];
}

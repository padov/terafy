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

  const AddQuickPatient({
    required this.fullName,
    required this.phone,
    this.email,
    this.dateOfBirth,
  });

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

  const PatientsLoaded({
    required this.patients,
    required this.filteredPatients,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [
    patients,
    filteredPatients,
    searchQuery,
    statusFilter,
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

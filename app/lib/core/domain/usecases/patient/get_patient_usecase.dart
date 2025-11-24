import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/features/patients/models/patient.dart';

class GetPatientUseCase {
  final PatientRepository repository;

  GetPatientUseCase(this.repository);

  Future<Patient> call(String id) {
    return repository.fetchPatientById(id);
  }
}

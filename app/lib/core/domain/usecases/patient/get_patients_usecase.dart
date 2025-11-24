import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/features/patients/models/patient.dart';

class GetPatientsUseCase {
  final PatientRepository repository;

  GetPatientsUseCase(this.repository);

  Future<List<Patient>> call() {
    return repository.fetchPatients();
  }
}

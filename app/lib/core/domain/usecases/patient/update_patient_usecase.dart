import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/features/patients/models/patient.dart';

class UpdatePatientUseCase {
  UpdatePatientUseCase(this._repository);

  final PatientRepository _repository;

  Future<Patient> call({required Patient patient}) async {
    return await _repository.updatePatient(patient: patient);
  }
}


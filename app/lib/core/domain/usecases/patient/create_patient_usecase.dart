import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/features/patients/models/patient.dart';

class CreatePatientUseCase {
  final PatientRepository repository;

  CreatePatientUseCase(this.repository);

  Future<Patient> call({
    required String fullName,
    required String phone,
    String? email,
    DateTime? birthDate,
  }) {
    return repository.createPatient(
      fullName: fullName,
      phone: phone,
      email: email,
      birthDate: birthDate,
    );
  }
}

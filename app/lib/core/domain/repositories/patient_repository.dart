import 'package:terafy/features/patients/models/patient.dart' as domain;

abstract class PatientRepository {
  Future<List<domain.Patient>> fetchPatients();

  Future<domain.Patient> fetchPatientById(String id);

  Future<domain.Patient> createPatient({
    required String fullName,
    required String phone,
    String? email,
    DateTime? birthDate,
  });

  Future<domain.Patient> updatePatient({required domain.Patient patient});
}

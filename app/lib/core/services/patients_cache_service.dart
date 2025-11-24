import 'package:terafy/features/patients/models/patient.dart';

class PatientsCacheService {
  List<Patient>? _patients;

  List<Patient>? getPatients() => _patients;

  void savePatients(List<Patient> patients) {
    _patients = List.unmodifiable(patients);
  }

  void clear() {
    _patients = null;
  }
}

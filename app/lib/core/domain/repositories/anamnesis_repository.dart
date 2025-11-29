import 'package:terafy/features/anamnesis/models/anamnesis.dart';

abstract class AnamnesisRepository {
  /// Busca anamnese por ID do paciente
  Future<Anamnesis?> fetchAnamnesisByPatientId(String patientId);

  /// Busca anamnese por ID
  Future<Anamnesis?> fetchAnamnesisById(String id);

  /// Cria uma nova anamnese
  Future<Anamnesis> createAnamnesis(Anamnesis anamnesis);

  /// Atualiza uma anamnese existente
  Future<Anamnesis> updateAnamnesis(String id, Anamnesis anamnesis);

  /// Deleta uma anamnese
  Future<void> deleteAnamnesis(String id);
}


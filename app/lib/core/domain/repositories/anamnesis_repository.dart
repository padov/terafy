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
  /// Deleta uma anamnese
  Future<void> deleteAnamnesis(String id);

  /// Cria um convite para preenchimento de anamnese
  /// Retorna o token do convite
  Future<String> createInvite(String patientId, String templateId);

  /// Obtém o contexto de um convite a partir do token (Público)
  Future<Map<String, dynamic>> getPublicInviteContext(String token);

  /// Submete uma anamnese a partir de um convite (Público)
  Future<void> submitPublicInvite(String token, Map<String, dynamic> data);
}

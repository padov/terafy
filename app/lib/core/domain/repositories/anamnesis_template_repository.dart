import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';

abstract class AnamnesisTemplateRepository {
  /// Lista todos os templates disponíveis (sistema + personalizados)
  Future<List<AnamnesisTemplate>> fetchTemplates({
    String? category,
    bool? isSystem,
  });

  /// Busca template por ID
  Future<AnamnesisTemplate?> fetchTemplateById(String id);

  /// Cria um novo template personalizado
  Future<AnamnesisTemplate> createTemplate(AnamnesisTemplate template);

  /// Atualiza um template existente
  Future<AnamnesisTemplate> updateTemplate(String id, AnamnesisTemplate template);

  /// Deleta um template (não pode deletar templates do sistema)
  Future<void> deleteTemplate(String id);
}


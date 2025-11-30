import 'message_channel.dart';

/// Template de mensagem reutilizável
class MessageTemplate {
  final int? id;
  final String name;
  final MessageType type;
  final MessageChannel channel;
  final String subjectTemplate;
  final String contentTemplate;
  final List<String> variables; // Lista de variáveis disponíveis no template
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageTemplate({
    this.id,
    required this.name,
    required this.type,
    required this.channel,
    required this.subjectTemplate,
    required this.contentTemplate,
    this.variables = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  MessageTemplate copyWith({
    int? id,
    String? name,
    MessageType? type,
    MessageChannel? channel,
    String? subjectTemplate,
    String? contentTemplate,
    List<String>? variables,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      subjectTemplate: subjectTemplate ?? this.subjectTemplate,
      contentTemplate: contentTemplate ?? this.contentTemplate,
      variables: variables ?? this.variables,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para mapa para inserção no banco
  Map<String, dynamic> toDatabaseMap() {
    return {
      'name': name,
      'type': type.name,
      'channel': channel.name,
      'subject_template': subjectTemplate,
      'content_template': contentTemplate,
      'variables': variables,
      'is_active': isActive,
    };
  }

  /// Cria a partir de um mapa do banco
  factory MessageTemplate.fromMap(Map<String, dynamic> map) {
    return MessageTemplate(
      id: map['id'] as int,
      name: map['name'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      channel: MessageChannel.values.firstWhere(
        (e) => e.name == map['channel'],
      ),
      subjectTemplate: map['subject_template'] as String,
      contentTemplate: map['content_template'] as String,
      variables: (map['variables'] as List?)?.cast<String>() ?? [],
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}


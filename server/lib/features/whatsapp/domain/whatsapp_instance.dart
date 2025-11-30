/// Status da instância WhatsApp
enum InstanceStatus {
  connected,
  disconnected,
  connecting,
}

/// Modelo de instância WhatsApp (Evolution API)
class WhatsAppInstance {
  final int? id;
  final int therapistId;
  final String instanceName;
  final String apiKey;
  final String phoneNumber;
  final InstanceStatus status;
  final String? webhookUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WhatsAppInstance({
    this.id,
    required this.therapistId,
    required this.instanceName,
    required this.apiKey,
    required this.phoneNumber,
    this.status = InstanceStatus.disconnected,
    this.webhookUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  WhatsAppInstance copyWith({
    int? id,
    int? therapistId,
    String? instanceName,
    String? apiKey,
    String? phoneNumber,
    InstanceStatus? status,
    String? webhookUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WhatsAppInstance(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      instanceName: instanceName ?? this.instanceName,
      apiKey: apiKey ?? this.apiKey,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'instance_name': instanceName,
      'api_key': apiKey,
      'phone_number': phoneNumber,
      'status': status.name,
      'webhook_url': webhookUrl,
    };
  }

  factory WhatsAppInstance.fromMap(Map<String, dynamic> map) {
    return WhatsAppInstance(
      id: map['id'] as int,
      therapistId: map['therapist_id'] as int,
      instanceName: map['instance_name'] as String,
      apiKey: map['api_key'] as String,
      phoneNumber: map['phone_number'] as String,
      status: InstanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InstanceStatus.disconnected,
      ),
      webhookUrl: map['webhook_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}


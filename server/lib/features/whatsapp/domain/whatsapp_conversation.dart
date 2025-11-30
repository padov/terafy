/// Estado da conversa WhatsApp
enum ConversationState {
  idle, // Aguardando interação
  identifying, // Identificando paciente
  menu, // Mostrando menu principal
  schedulingDate, // Escolhendo data
  schedulingTime, // Escolhendo horário
  confirming, // Confirmando agendamento
  viewingAppointments, // Visualizando agendamentos
  canceling, // Cancelando agendamento
}

/// Modelo de conversa WhatsApp
class WhatsAppConversation {
  final int? id;
  final String phoneNumber;
  final int? patientId;
  final int therapistId;
  final ConversationState currentState;
  final Map<String, dynamic> contextData;
  final DateTime lastInteractionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WhatsAppConversation({
    this.id,
    required this.phoneNumber,
    this.patientId,
    required this.therapistId,
    this.currentState = ConversationState.idle,
    this.contextData = const {},
    required this.lastInteractionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  WhatsAppConversation copyWith({
    int? id,
    String? phoneNumber,
    int? patientId,
    int? therapistId,
    ConversationState? currentState,
    Map<String, dynamic>? contextData,
    DateTime? lastInteractionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WhatsAppConversation(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      currentState: currentState ?? this.currentState,
      contextData: contextData ?? this.contextData,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'phone_number': phoneNumber,
      'patient_id': patientId,
      'therapist_id': therapistId,
      'current_state': currentState.name,
      'context_data': contextData,
      'last_interaction_at': lastInteractionAt.toUtc().toIso8601String(),
    };
  }

  factory WhatsAppConversation.fromMap(Map<String, dynamic> map) {
    return WhatsAppConversation(
      id: map['id'] as int,
      phoneNumber: map['phone_number'] as String,
      patientId: map['patient_id'] as int?,
      therapistId: map['therapist_id'] as int,
      currentState: ConversationState.values.firstWhere(
        (e) => e.name == map['current_state'],
        orElse: () => ConversationState.idle,
      ),
      contextData: map['context_data'] != null
          ? Map<String, dynamic>.from(map['context_data'] as Map)
          : {},
      lastInteractionAt: DateTime.parse(map['last_interaction_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}


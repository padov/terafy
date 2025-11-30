import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/whatsapp/domain/whatsapp_conversation.dart';
import 'package:server/features/whatsapp/whatsapp.repository.dart';
import 'package:common/common.dart';

/// Gerenciador de conversas WhatsApp
/// Gerencia o estado e fluxo de conversação com pacientes
class ConversationManager {
  final WhatsAppRepository _whatsappRepository;
  final PatientRepository _patientRepository;
  final ScheduleRepository _scheduleRepository;

  ConversationManager(
    this._whatsappRepository,
    this._patientRepository,
    this._scheduleRepository,
  );

  /// Processa uma mensagem recebida
  Future<ConversationResponse> processMessage({
    required String phoneNumber,
    required int therapistId,
    required String messageText,
    String? buttonId,
    String? listItemId,
  }) async {
    AppLogger.func();

    // Busca ou cria conversa
    var conversation = await _whatsappRepository.getOrCreateConversation(
      phoneNumber: phoneNumber,
      therapistId: therapistId,
    );

    // Atualiza última interação
    conversation = conversation.copyWith(
      lastInteractionAt: DateTime.now(),
    );

    // Processa de acordo com o estado atual
    switch (conversation.currentState) {
      case ConversationState.idle:
      case ConversationState.menu:
        return await _handleMenuState(conversation, messageText, buttonId);

      case ConversationState.identifying:
        return await _handleIdentifyingState(conversation, messageText);

      case ConversationState.schedulingDate:
        return await _handleSchedulingDateState(conversation, messageText, buttonId);

      case ConversationState.schedulingTime:
        return await _handleSchedulingTimeState(conversation, messageText, buttonId);

      case ConversationState.confirming:
        return await _handleConfirmingState(conversation, buttonId);

      case ConversationState.viewingAppointments:
        return await _showAppointments(conversation);

      case ConversationState.canceling:
        return await _handleCancelingState(conversation, messageText, buttonId);
    }
  }

  /// Responde ao estado de menu
  Future<ConversationResponse> _handleMenuState(
    WhatsAppConversation conversation,
    String messageText,
    String? buttonId,
  ) async {
    final command = (buttonId ?? messageText).toLowerCase().trim();

    if (command == 'agendar' || command == 'agendar consulta' || command.contains('agendar')) {
      // Identifica paciente se ainda não identificado
      if (conversation.patientId == null) {
        final patientId = await _identifyPatient(conversation.phoneNumber, conversation.therapistId);
        if (patientId == null) {
          return ConversationResponse(
            message: 'Olá! Para agendar uma consulta, preciso identificá-lo.\n\nPor favor, informe seu CPF ou código de vinculação.',
            nextState: ConversationState.identifying,
            conversation: conversation.copyWith(currentState: ConversationState.identifying),
          );
        }
        conversation = conversation.copyWith(patientId: patientId);
      }

      // Mostra próximas datas disponíveis
      return ConversationResponse(
        message: 'Vamos agendar sua consulta! Escolha uma data:',
        nextState: ConversationState.schedulingDate,
        conversation: conversation.copyWith(currentState: ConversationState.schedulingDate),
        buttons: await _getAvailableDates(conversation.therapistId),
      );
    } else if (command == 'meus agendamentos' || command.contains('agendamento')) {
      if (conversation.patientId == null) {
        final patientId = await _identifyPatient(conversation.phoneNumber, conversation.therapistId);
        if (patientId == null) {
          return ConversationResponse(
            message: 'Para ver seus agendamentos, preciso identificá-lo.\n\nPor favor, informe seu CPF.',
            nextState: ConversationState.identifying,
            conversation: conversation.copyWith(currentState: ConversationState.identifying),
          );
        }
        conversation = conversation.copyWith(patientId: patientId);
      }

      return await _showAppointments(conversation);
    } else if (command == 'cancelar' || command.contains('cancelar')) {
      if (conversation.patientId == null) {
        final patientId = await _identifyPatient(conversation.phoneNumber, conversation.therapistId);
        if (patientId == null) {
          return ConversationResponse(
            message: 'Para cancelar um agendamento, preciso identificá-lo.\n\nPor favor, informe seu CPF.',
            nextState: ConversationState.identifying,
            conversation: conversation.copyWith(currentState: ConversationState.identifying),
          );
        }
        conversation = conversation.copyWith(patientId: patientId);
      }

      return await _showAppointmentsToCancel(conversation);
    } else {
      // Menu principal
      return ConversationResponse(
        message: 'Olá! Como posso ajudar?\n\nEscolha uma opção:',
        nextState: ConversationState.menu,
        conversation: conversation.copyWith(currentState: ConversationState.menu),
        buttons: [
          {'id': 'agendar', 'text': '📅 Agendar Consulta'},
          {'id': 'meus_agendamentos', 'text': '📋 Meus Agendamentos'},
          {'id': 'cancelar', 'text': '❌ Cancelar Agendamento'},
        ],
      );
    }
  }

  /// Identifica paciente pelo telefone ou CPF
  Future<int?> _identifyPatient(String phoneNumber, int therapistId) async {
    try {
      // Busca por telefone
      final patients = await _patientRepository.getPatients(
        therapistId: therapistId,
        userId: null,
        userRole: null,
        accountId: therapistId,
        bypassRLS: true,
      );

      for (final patient in patients) {
        if (patient.phones != null) {
          for (final phone in patient.phones!) {
            // Normaliza telefones para comparação
            final normalizedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
            final normalizedInput = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
            if (normalizedPhone.endsWith(normalizedInput) || normalizedInput.endsWith(normalizedPhone)) {
              return patient.id;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
    }
    return null;
  }

  /// Busca datas disponíveis
  Future<List<Map<String, String>>> _getAvailableDates(int therapistId) async {
    // TODO: Implementar busca de horários disponíveis
    // Por enquanto, retorna próximos 7 dias
    final dates = <Map<String, String>>[];
    final now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      dates.add({
        'id': 'date_${date.toIso8601String().split('T')[0]}',
        'text': _formatDate(date),
      });
    }
    return dates;
  }

  /// Formata data em português
  String _formatDate(DateTime date) {
    final days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  /// Responde ao estado de identificação
  Future<ConversationResponse> _handleIdentifyingState(
    WhatsAppConversation conversation,
    String messageText,
  ) async {
    // TODO: Implementar busca por CPF ou código de vinculação
    return ConversationResponse(
      message: 'Identificação ainda não implementada. Por favor, entre em contato com o terapeuta.',
      nextState: ConversationState.idle,
      conversation: conversation.copyWith(currentState: ConversationState.idle),
    );
  }

  /// Responde ao estado de agendamento de data
  Future<ConversationResponse> _handleSchedulingDateState(
    WhatsAppConversation conversation,
    String messageText,
    String? buttonId,
  ) async {
    // TODO: Implementar seleção de data e mostrar horários
    return ConversationResponse(
      message: 'Seleção de data ainda não implementada completamente.',
      nextState: ConversationState.schedulingDate,
      conversation: conversation,
    );
  }

  /// Responde ao estado de agendamento de horário
  Future<ConversationResponse> _handleSchedulingTimeState(
    WhatsAppConversation conversation,
    String messageText,
    String? buttonId,
  ) async {
    // TODO: Implementar seleção de horário e confirmação
    return ConversationResponse(
      message: 'Seleção de horário ainda não implementada completamente.',
      nextState: ConversationState.schedulingTime,
      conversation: conversation,
    );
  }

  /// Responde ao estado de confirmação
  Future<ConversationResponse> _handleConfirmingState(
    WhatsAppConversation conversation,
    String? buttonId,
  ) async {
    // TODO: Implementar confirmação de agendamento
    return ConversationResponse(
      message: 'Confirmação ainda não implementada.',
      nextState: ConversationState.idle,
      conversation: conversation.copyWith(currentState: ConversationState.idle),
    );
  }

  /// Mostra agendamentos do paciente
  Future<ConversationResponse> _showAppointments(WhatsAppConversation conversation) async {
    // TODO: Implementar busca e exibição de agendamentos
    return ConversationResponse(
      message: 'Visualização de agendamentos ainda não implementada.',
      nextState: ConversationState.idle,
      conversation: conversation.copyWith(currentState: ConversationState.idle),
    );
  }

  /// Mostra agendamentos para cancelar
  Future<ConversationResponse> _showAppointmentsToCancel(WhatsAppConversation conversation) async {
    // TODO: Implementar busca e cancelamento de agendamentos
    return ConversationResponse(
      message: 'Cancelamento ainda não implementado.',
      nextState: ConversationState.idle,
      conversation: conversation.copyWith(currentState: ConversationState.idle),
    );
  }

  /// Responde ao estado de cancelamento
  Future<ConversationResponse> _handleCancelingState(
    WhatsAppConversation conversation,
    String messageText,
    String? buttonId,
  ) async {
    // TODO: Implementar cancelamento
    return ConversationResponse(
      message: 'Cancelamento ainda não implementado.',
      nextState: ConversationState.idle,
      conversation: conversation.copyWith(currentState: ConversationState.idle),
    );
  }
}

/// Resposta do processamento de conversa
class ConversationResponse {
  final String message;
  final ConversationState nextState;
  final WhatsAppConversation conversation;
  final List<Map<String, String>>? buttons;
  final List<Map<String, dynamic>>? listItems;

  const ConversationResponse({
    required this.message,
    required this.nextState,
    required this.conversation,
    this.buttons,
    this.listItems,
  });
}


import 'package:common/common.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/whatsapp/domain/whatsapp_instance.dart';
import 'package:server/features/whatsapp/services/conversation_manager.dart';
import 'package:server/features/whatsapp/services/whatsapp_appointment_service.dart';
import 'package:server/features/whatsapp/services/whatsapp_confirmation_service.dart';
import 'package:server/features/whatsapp/whatsapp.repository.dart';
import 'package:server/features/whatsapp/whatsapp.webhook_handler.dart';

class WhatsAppException implements Exception {
  final String message;
  final int statusCode;

  WhatsAppException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class WhatsAppController {
  final WhatsAppRepository _whatsappRepository;
  final ConversationManager _conversationManager;
  final WhatsAppAppointmentService _appointmentService;
  final WhatsAppConfirmationService _confirmationService;
  final WhatsAppWebhookHandler _webhookHandler;
  final ScheduleRepository _scheduleRepository;

  WhatsAppController(
    this._whatsappRepository,
    this._conversationManager,
    this._appointmentService,
    this._confirmationService,
    this._webhookHandler,
    this._scheduleRepository,
  );

  /// Processa webhook do Evolution API
  Future<void> processWebhook(Map<String, dynamic> event) async {
    AppLogger.func();

    try {
      await _webhookHandler.processWebhookEvent(event);
    } catch (e) {
      throw WhatsAppException('Erro ao processar webhook: ${e.toString()}', 500);
    }
  }

  /// Envia confirmações de agendamento para um terapeuta
  Future<int> sendConfirmations({
    required int therapistId,
    required int daysBefore,
  }) async {
    AppLogger.func();

    try {
      await _confirmationService.sendAppointmentConfirmations(
        therapistId: therapistId,
        daysBefore: daysBefore,
      );
      return 1; // TODO: Retornar contagem real
    } catch (e) {
      throw WhatsAppException('Erro ao enviar confirmações: ${e.toString()}', 500);
    }
  }

  /// Busca ou cria instância WhatsApp
  Future<WhatsAppInstance> getOrCreateInstance({
    required int therapistId,
    required String instanceName,
    required String apiKey,
    required String phoneNumber,
  }) async {
    AppLogger.func();

    try {
      final existing = await _whatsappRepository.getInstanceByTherapist(therapistId);
      if (existing != null) {
        return existing;
      }

      final instance = WhatsAppInstance(
        therapistId: therapistId,
        instanceName: instanceName,
        apiKey: apiKey,
        phoneNumber: phoneNumber,
        status: InstanceStatus.disconnected,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _whatsappRepository.upsertInstance(instance);
    } catch (e) {
      throw WhatsAppException('Erro ao criar instância: ${e.toString()}', 500);
    }
  }

  /// Busca horários disponíveis
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int therapistId,
    required DateTime date,
    required int userId,
    String? userRole,
  }) async {
    AppLogger.func();

    try {
      return await _appointmentService.findAvailableSlots(
        therapistId: therapistId,
        date: date,
        userId: userId,
        userRole: userRole,
      );
    } catch (e) {
      throw WhatsAppException('Erro ao buscar horários: ${e.toString()}', 500);
    }
  }
}


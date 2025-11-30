import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/subscription/subscription.controller.dart';

class PatientException implements Exception {
  final String message;
  final int statusCode;

  PatientException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class PatientController {
  final PatientRepository _repository;
  final SubscriptionController? _subscriptionController;

  PatientController(this._repository, [this._subscriptionController]);

  Future<List<Patient>> listPatients({
    required int userId,
    String? userRole,
    int? therapistId,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return await _repository.getPatients(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      throw PatientException('Erro ao listar pacientes: ${e.toString()}', 500);
    }
  }

  Future<Patient> getPatientById(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      final patient = await _repository.getPatientById(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );

      if (patient == null) {
        throw PatientException('Paciente não encontrado', 404);
      }

      return patient;
    } catch (e) {
      if (e is PatientException) rethrow;
      throw PatientException('Erro ao buscar paciente: ${e.toString()}', 500);
    }
  }

  Future<Patient> createPatient({
    required Patient patient,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();

    try {
      // Valida limite de pacientes se subscription controller estiver disponível
      if (_subscriptionController != null && !bypassRLS) {
        final canCreate = await _subscriptionController!.canCreatePatient(userId);
        if (!canCreate) {
          final usage = await _subscriptionController!.getUsageInfo(userId);
          final patientCount = usage['patient_count'] as int;
          final patientLimit = usage['patient_limit'] as int;
          throw PatientException(
            'Limite de pacientes atingido. Você possui $patientCount de $patientLimit pacientes permitidos no seu plano atual. Faça upgrade para adicionar mais pacientes.',
            403,
          );
        }
      }

      return await _repository.createPatient(
        patient,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? patient.therapistId,
        bypassRLS: bypassRLS,
      );
    } on PatientException {
      rethrow;
    } on ServerException catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      if (e.code == '23505') {
        throw PatientException('CPF já cadastrado para outro paciente.', 409);
      }
      // Verifica se é erro de limite de pacientes (trigger do banco)
      if (e.message.contains('Limite de pacientes atingido')) {
        throw PatientException(e.message, 403);
      }
      throw PatientException('Erro ao criar paciente: ${e.message}', 500);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      // Verifica se é erro de limite de pacientes (trigger do banco)
      if (e.toString().contains('Limite de pacientes atingido')) {
        throw PatientException(e.toString(), 403);
      }
      throw PatientException('Erro ao criar paciente: ${e.toString()}', 500);
    }
  }

  Future<Patient> updatePatient(
    int id, {
    required Patient patient,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      final updated = await _repository.updatePatient(
        id,
        patient,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? patient.therapistId,
        bypassRLS: bypassRLS,
      );

      if (updated == null) {
        throw PatientException('Paciente não encontrado', 404);
      }

      return updated;
    } on ServerException catch (e) {
      if (e.code == '23505') {
        throw PatientException('CPF já cadastrado para outro paciente.', 409);
      }
      throw PatientException('Erro ao atualizar paciente: ${e.message}', 500);
    } catch (e) {
      if (e is PatientException) rethrow;
      throw PatientException('Erro ao atualizar paciente: ${e.toString()}', 500);
    }
  }

  Future<void> deletePatient(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      final deleted = await _repository.deletePatient(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );

      if (!deleted) {
        throw PatientException('Paciente não encontrado', 404);
      }
    } catch (e) {
      if (e is PatientException) rethrow;
      throw PatientException('Erro ao remover paciente: ${e.toString()}', 500);
    }
  }
}

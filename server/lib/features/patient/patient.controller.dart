import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/features/patient/patient.repository.dart';

class PatientException implements Exception {
  final String message;
  final int statusCode;

  PatientException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class PatientController {
  final PatientRepository _repository;

  PatientController(this._repository);

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
      return await _repository.createPatient(
        patient,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? patient.therapistId,
        bypassRLS: bypassRLS,
      );
    } on ServerException catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      if (e.code == '23505') {
        throw PatientException('CPF já cadastrado para outro paciente.', 409);
      }
      throw PatientException('Erro ao criar paciente: ${e.message}', 500);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
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

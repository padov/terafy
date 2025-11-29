import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:server/features/patient/patient.routes.dart';

class PatientHandler extends BaseHandler {
  final PatientController _controller;

  PatientHandler(this._controller);

  @override
  Router get router => configurePatientRoutes(this);

  Future<Response> handleList(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistFilter;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil antes de cadastrar pacientes.',
          );
        }
        therapistFilter = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null && therapistIdParam.isNotEmpty) {
          therapistFilter = int.tryParse(therapistIdParam);
          if (therapistFilter == null) {
            return badRequestResponse('Parâmetro therapistId inválido');
          }
        }
      }

      final patients = await _controller.listPatients(
        userId: userId,
        userRole: userRole,
        therapistId: therapistFilter,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse(patients.map((patient) => patient.toJson()).toList());
    } on PatientException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao listar pacientes: ${e.toString()}');
    }
  }

  Future<Response> handleGetById(Request request, String id) async {
    AppLogger.func();

    try {
      final patientId = int.tryParse(id);
      if (patientId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final patient = await _controller.getPatientById(
        patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse(patient.toJson());
    } on PatientException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar paciente: ${e.toString()}');
    }
  }

  Future<Response> handleCreate(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      int? therapistId = _readInt(data, ['therapistId', 'therapist_id']);

      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil antes de cadastrar pacientes.',
          );
        }
        therapistId = accountId;
      } else if (userRole != 'admin') {
        return forbiddenResponse('Apenas terapeutas ou administradores podem criar pacientes');
      }

      if (therapistId == null) {
        return badRequestResponse('Informe o therapistId para vincular o paciente ao terapeuta responsável.');
      }

      final patient = _patientFromRequestMap(data: data, therapistId: therapistId);

      final created = await _controller.createPatient(
        patient: patient,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
        bypassRLS: userRole == 'admin',
      );

      return createdResponse(created.toJson());
    } on PatientException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao criar paciente: ${e.toString()}');
    }
  }

  Future<Response> handleUpdate(Request request, String id) async {
    AppLogger.func();

    try {
      final patientId = int.tryParse(id);
      if (patientId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final existing = await _controller.getPatientById(
        patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      int therapistId = existing.therapistId;
      if (userRole == 'admin') {
        final therapistFromBody = _readInt(data, ['therapistId', 'therapist_id']);
        therapistId = therapistFromBody ?? therapistId;
      } else if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil antes de atualizar pacientes.',
          );
        }
        therapistId = accountId;
      }

      final updatedPatient = _patientFromRequestMap(data: data, therapistId: therapistId, base: existing);

      final result = await _controller.updatePatient(
        patientId,
        patient: updatedPatient,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse(result.toJson());
    } on PatientException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao atualizar paciente: ${e.toString()}');
    }
  }

  Future<Response> handleDelete(Request request, String id) async {
    AppLogger.func();

    try {
      final patientId = int.tryParse(id);
      if (patientId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deletePatient(
        patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse({'message': 'Paciente removido com sucesso'});
    } on PatientException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao remover paciente: ${e.toString()}');
    }
  }

  Patient _patientFromRequestMap({required Map<String, dynamic> data, required int therapistId, Patient? base}) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value);
      }
      return null;
    }

    Map<String, dynamic>? _parseJson(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    List<String>? _parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').where((element) => element.isNotEmpty).toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    return Patient(
      id: base?.id,
      therapistId: therapistId,
      userId: _readInt(data, ['userId', 'user_id']) ?? base?.userId,
      fullName: _readString(data, ['fullName', 'full_name']) ?? base?.fullName ?? '',
      birthDate: _parseDate(_read<dynamic>(data, ['birthDate', 'birth_date'])) ?? base?.birthDate,
      age: _readInt(data, ['age']) ?? base?.age,
      cpf: _readString(data, ['cpf']) ?? base?.cpf,
      rg: _readString(data, ['rg']) ?? base?.rg,
      gender: _readString(data, ['gender']) ?? base?.gender,
      maritalStatus: _readString(data, ['maritalStatus', 'marital_status']) ?? base?.maritalStatus,
      address: _readString(data, ['address']) ?? base?.address,
      email: _readString(data, ['email']) ?? base?.email,
      phones: _parseStringList(_read<dynamic>(data, ['phones'])) ?? base?.phones,
      profession: _readString(data, ['profession']) ?? base?.profession,
      education: _readString(data, ['education']) ?? base?.education,
      emergencyContact:
          _parseJson(_read<dynamic>(data, ['emergencyContact', 'emergency_contact'])) ?? base?.emergencyContact,
      legalGuardian: _parseJson(_read<dynamic>(data, ['legalGuardian', 'legal_guardian'])) ?? base?.legalGuardian,
      healthInsurance: _readString(data, ['healthInsurance', 'health_insurance']) ?? base?.healthInsurance,
      healthInsuranceCard:
          _readString(data, ['healthInsuranceCard', 'health_insurance_card']) ?? base?.healthInsuranceCard,
      preferredPaymentMethod:
          _readString(data, ['preferredPaymentMethod', 'preferred_payment_method']) ?? base?.preferredPaymentMethod,
      sessionPrice: _parseDouble(_read<dynamic>(data, ['sessionPrice', 'session_price'])) ?? base?.sessionPrice,
      consentSignedAt:
          _parseDate(_read<dynamic>(data, ['consentSignedAt', 'consent_signed_at'])) ?? base?.consentSignedAt,
      lgpdConsentAt: _parseDate(_read<dynamic>(data, ['lgpdConsentAt', 'lgpd_consent_at'])) ?? base?.lgpdConsentAt,
      status: _readString(data, ['status']) ?? base?.status ?? 'active',
      inactivationReason: _readString(data, ['inactivationReason', 'inactivation_reason']) ?? base?.inactivationReason,
      treatmentStartDate:
          _parseDate(_read<dynamic>(data, ['treatmentStartDate', 'treatment_start_date'])) ?? base?.treatmentStartDate,
      lastSessionDate:
          _parseDate(_read<dynamic>(data, ['lastSessionDate', 'last_session_date'])) ?? base?.lastSessionDate,
      tags: _parseStringList(_read<dynamic>(data, ['tags'])) ?? base?.tags,
      notes: _readString(data, ['notes']) ?? base?.notes,
      photoUrl: _readString(data, ['photoUrl', 'photo_url']) ?? base?.photoUrl,
      color: _readString(data, ['color']) ?? base?.color,
      createdAt: base?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    final value = _read<dynamic>(data, keys);
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    final value = _read<dynamic>(data, keys);
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static T? _read<T>(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key] as T?;
      }
    }
    return null;
  }
}

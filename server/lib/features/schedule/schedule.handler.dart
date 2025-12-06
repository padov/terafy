import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/schedule/schedule.controller.dart';
import 'package:server/features/schedule/schedule.routes.dart';

class ScheduleHandler extends BaseHandler {
  ScheduleHandler(this._controller);

  final ScheduleController _controller;

  @override
  Router get router => configureScheduleRoutes(this);

  Future<Response> handleGetSettings(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para consultar.');
        }
        therapistId = int.tryParse(therapistIdParam) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem acessar estas configurações.');
      }

      final settings = await _controller.getOrCreateSettings(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
      );

      return successResponse(settings.toJson());
    } on ScheduleException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao carregar configurações de agenda: ${e.toString()}');
    }
  }

  Future<Response> handleUpdateSettings(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio.');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para atualizar.');
        }
        therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem atualizar estas configurações.');
      }

      final settings = TherapistScheduleSettings.fromJson({...data, 'therapistId': therapistId});

      final updated = await _controller.updateSettings(settings: settings, userId: userId, userRole: userRole);

      return successResponse(updated.toJson());
    } on ScheduleException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar configurações de agenda: ${e.toString()}');
    }
  }

  Future<Response> handleListAppointments(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final startParam = request.url.queryParameters['start'];
      final endParam = request.url.queryParameters['end'];

      if (startParam == null || endParam == null) {
        return badRequestResponse('Parâmetros start e end são obrigatórios.');
      }

      final start = DateTime.tryParse(startParam);
      final end = DateTime.tryParse(endParam);

      if (start == null || end == null || !end.isAfter(start)) {
        return badRequestResponse('Intervalo de datas inválido.');
      }

      int therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para consultar.');
        }
        therapistId = int.tryParse(therapistIdParam) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem acessar a agenda.');
      }

      final appointments = await _controller.listAppointments(
        therapistId: therapistId,
        start: start,
        end: end,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(appointments.map((appointment) => appointment.toJson()).toList());
    } on ScheduleException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao listar agendamentos: ${e.toString()}');
    }
  }

  Future<Response> handleGetAppointment(Request request, String id) async {
    AppLogger.func();
    try {
      final appointmentId = int.tryParse(id);
      if (appointmentId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null) {
          therapistId = int.tryParse(therapistIdParam) ?? (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem acessar agendamentos.');
      }

      final appointment = await _controller.getAppointment(
        appointmentId: appointmentId,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      // Verificação adicional de segurança: therapist só acessa seus próprios agendamentos
      // (camada adicional caso o RLS não bloqueie corretamente)
      // TODO: coisa estranha isso aqui, nao deveria acontecer
      if (userRole == 'therapist' && therapistId != null && appointment.therapistId != therapistId) {
        return errorResponse('Agendamento não encontrado', statusCode: 404);
      }

      return successResponse(appointment.toJson());
    } on ScheduleException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar agendamento: ${e.toString()}');
    }
  }

  Future<Response> handleCreateAppointment(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para criar.');
        }
        therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem criar agendamentos.');
      }

      final appointment = Appointment.fromJson({...data, 'therapistId': therapistId});

      final created = await _controller.createAppointment(
        appointment: appointment,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return createdResponse(created.toJson());
    } on ScheduleException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao criar agendamento: ${e.toString()}');
    }
  }

  Future<Response> handleUpdateAppointment(Request request, String id) async {
    AppLogger.func();
    try {
      final appointmentId = int.tryParse(id);
      if (appointmentId == null) {
        return badRequestResponse('ID inválido');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para atualizar.');
        }
        therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem atualizar agendamentos.');
      }

      final existing = await _controller.updateAppointment(
        appointmentId: appointmentId,
        appointment: Appointment.fromJson({...data, 'therapistId': therapistId}),
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(existing.toJson());
    } on ScheduleException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar agendamento: ${e.toString()}');
    }
  }

  Future<Response> handleValidateAvailability(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawSlots = data['slots'] as List<dynamic>?;

      if (rawSlots == null || rawSlots.isEmpty) {
        return successResponse([]); // Sem slots para validar, sem conflitos
      }

      final slots = rawSlots.map((s) {
        return {'start': DateTime.parse(s['start']), 'end': DateTime.parse(s['end'])};
      }).toList();

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'admin' && data.containsKey('therapistId')) {
        therapistId = int.tryParse(data['therapistId'].toString());
      } else if (userRole == 'therapist') {
        therapistId = accountId;
      }

      // Se for admin, passa o therapistId via accountId para o controller usar como contexto?
      // Ou ajustamos o controller para receber therapistId explícito?
      // O controller usa accountId ?? therapistId para RLS.
      // Vamos passar o therapistId como accountId se for admin, ou deixar null para controller reclamar se necessário.
      // Melhor: Se for admin e tiver therapistId, passamos como accountId para o método.

      final conflictingSlots = await _controller.validateAppointments(
        slots: slots,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(
        conflictingSlots
            .map((s) => {'start': s['start'].toIso8601String(), 'end': s['end'].toIso8601String()})
            .toList(),
      );
    } on ScheduleException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse('Formato de data inválido ou JSON malformado: ${e.message}');
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao validar agendamentos: ${e.toString()}');
    }
  }

  Future<Response> handleDeleteAppointment(Request request, String id) async {
    AppLogger.func();
    try {
      final appointmentId = int.tryParse(id);
      if (appointmentId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteAppointment(
        appointmentId: appointmentId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse({'message': 'Agendamento removido com sucesso'});
    } on ScheduleException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao remover agendamento: ${e.toString()}');
    }
  }
}

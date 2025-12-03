import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/session/session.controller.dart';
import 'package:server/features/session/session.routes.dart';

class SessionHandler extends BaseHandler {
  SessionHandler(this._controller);

  final SessionController _controller;

  @override
  Router get router => configureSessionRoutes(this);

  Future<Response> handleCreateSession(Request request) async {
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

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil primeiro.',
          );
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para criar sessão.');
        }
        therapistId =
            int.tryParse(therapistIdParam.toString()) ??
            (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem criar sessões.',
        );
      }

      final session = Session.fromJson({
        ...data,
        'therapistId': therapistId,
        'sessionNumber': data['sessionNumber'] ?? 0, // Será calculado pelo controller se <= 0
        'type': data['type'] ?? 'presential',
        'modality': data['modality'] ?? 'individual',
        'status': data['status'] ?? 'scheduled',
        'paymentStatus': data['paymentStatus'] ?? 'pending',
      });

      final created = await _controller.createSession(
        session: session,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(created.toJson());
    } on SessionException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao criar sessão: ${e.toString()}',
      );
    }
  }

  Future<Response> handleGetSession(Request request, String id) async {
    AppLogger.func();
    try {
      final sessionId = int.tryParse(id);
      if (sessionId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final session = await _controller.getSession(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(session.toJson());
    } on SessionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao buscar sessão: ${e.toString()}',
      );
    }
  }

  Future<Response> handleListSessions(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil primeiro.',
          );
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null) {
          therapistId =
              int.tryParse(therapistIdParam) ??
              (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem acessar sessões.',
        );
      }

      final patientIdParam = request.url.queryParameters['patientId'];
      final appointmentIdParam = request.url.queryParameters['appointmentId'];
      final statusParam = request.url.queryParameters['status'];
      final startParam = request.url.queryParameters['start'];
      final endParam = request.url.queryParameters['end'];

      int? patientId = patientIdParam != null
          ? int.tryParse(patientIdParam)
          : null;
      int? appointmentId = appointmentIdParam != null
          ? int.tryParse(appointmentIdParam)
          : null;
      DateTime? startDate = startParam != null
          ? DateTime.tryParse(startParam)
          : null;
      DateTime? endDate = endParam != null ? DateTime.tryParse(endParam) : null;

      final sessions = await _controller.listSessions(
        patientId: patientId,
        therapistId: therapistId,
        appointmentId: appointmentId,
        status: statusParam,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(
        sessions.map((session) => session.toJson()).toList(),
      );
    } on SessionException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao listar sessões: ${e.toString()}',
      );
    }
  }

  Future<Response> handleUpdateSession(Request request, String id) async {
    AppLogger.func();
    try {
      final sessionId = int.tryParse(id);
      if (sessionId == null) {
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

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil primeiro.',
          );
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam != null) {
          therapistId =
              int.tryParse(therapistIdParam.toString()) ??
              (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem atualizar sessões.',
        );
      }

      final session = Session.fromJson({
        ...data,
        if (therapistId != null) 'therapistId': therapistId,
        'sessionNumber': data['sessionNumber'] ?? 0, // Será calculado pelo controller se <= 0
        'type': data['type'] ?? 'presential',
        'modality': data['modality'] ?? 'individual',
        'status': data['status'] ?? 'scheduled',
        'paymentStatus': data['paymentStatus'] ?? 'pending',
      });

      final updated = await _controller.updateSession(
        sessionId: sessionId,
        session: session,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(updated.toJson());
    } on SessionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao atualizar sessão: ${e.toString()}',
      );
    }
  }

  Future<Response> handleDeleteSession(Request request, String id) async {
    AppLogger.func();
    try {
      final sessionId = int.tryParse(id);
      if (sessionId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteSession(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse({'message': 'Sessão removida com sucesso'});
    } on SessionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao remover sessão: ${e.toString()}',
      );
    }
  }

  Future<Response> handleGetNextSessionNumber(Request request) async {
    AppLogger.func();
    try {
      final patientIdParam = request.url.queryParameters['patientId'];
      if (patientIdParam == null) {
        return badRequestResponse('Parâmetro patientId é obrigatório');
      }

      final patientId = int.tryParse(patientIdParam);
      if (patientId == null) {
        return badRequestResponse('patientId inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final nextNumber = await _controller.getNextSessionNumber(
        patientId: patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse({'nextNumber': nextNumber});
    } on SessionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao calcular próximo número de sessão: ${e.toString()}',
      );
    }
  }
}

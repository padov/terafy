import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/financial/financial.controller.dart';
import 'package:server/features/financial/financial.routes.dart';

class FinancialHandler extends BaseHandler {
  FinancialHandler(this._controller);

  final FinancialController _controller;

  @override
  Router get router => configureFinancialRoutes(this);

  Future<Response> handleCreateTransaction(Request request) async {
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
          return badRequestResponse('Informe o therapistId para criar transação.');
        }
        therapistId =
            int.tryParse(therapistIdParam.toString()) ??
            (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem criar transações.',
        );
      }

      final transaction = FinancialTransaction.fromJson({
        ...data,
        'therapistId': therapistId,
      });

      final created = await _controller.createTransaction(
        transaction: transaction,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(created.toJson(), statusCode: 201);
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao criar transação: ${e.toString()}',
      );
    }
  }

  Future<Response> handleGetTransaction(Request request, String id) async {
    AppLogger.func();
    try {
      final transactionId = int.tryParse(id);
      if (transactionId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final transaction = await _controller.getTransaction(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      if (transaction == null) {
        return notFoundResponse('Transação não encontrada');
      }

      return successResponse(transaction.toJson());
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao buscar transação: ${e.toString()}',
      );
    }
  }

  Future<Response> handleListTransactions(Request request) async {
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
          therapistId = int.tryParse(therapistIdParam);
        }
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem listar transações.',
        );
      }

      // Parse query parameters
      final patientIdParam = request.url.queryParameters['patientId'];
      final sessionIdParam = request.url.queryParameters['sessionId'];
      final statusParam = request.url.queryParameters['status'];
      final categoryParam = request.url.queryParameters['category'];
      final startDateParam = request.url.queryParameters['startDate'];
      final endDateParam = request.url.queryParameters['endDate'];

      int? patientId;
      if (patientIdParam != null) {
        patientId = int.tryParse(patientIdParam);
      }

      int? sessionId;
      if (sessionIdParam != null) {
        sessionId = int.tryParse(sessionIdParam);
      }

      DateTime? startDate;
      if (startDateParam != null) {
        startDate = DateTime.tryParse(startDateParam);
      }

      DateTime? endDate;
      if (endDateParam != null) {
        endDate = DateTime.tryParse(endDateParam);
      }

      final transactions = await _controller.listTransactions(
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        therapistId: therapistId,
        patientId: patientId,
        sessionId: sessionId,
        status: statusParam,
        category: categoryParam,
        startDate: startDate,
        endDate: endDate,
      );

      return successResponse(
        transactions.map((t) => t.toJson()).toList(),
      );
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao listar transações: ${e.toString()}',
      );
    }
  }

  Future<Response> handleUpdateTransaction(Request request, String id) async {
    AppLogger.func();
    try {
      final transactionId = int.tryParse(id);
      if (transactionId == null) {
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

      // Buscar transação existente para manter campos não fornecidos
      final existing = await _controller.getTransaction(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      if (existing == null) {
        return notFoundResponse('Transação não encontrada');
      }

      final transaction = FinancialTransaction.fromJson({
        ...existing.toJson(),
        ...data,
        'id': transactionId, // Garantir que o ID não seja alterado
      });

      final updated = await _controller.updateTransaction(
        transactionId: transactionId,
        transaction: transaction,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(updated.toJson());
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao atualizar transação: ${e.toString()}',
      );
    }
  }

  Future<Response> handleDeleteTransaction(Request request, String id) async {
    AppLogger.func();
    try {
      final transactionId = int.tryParse(id);
      if (transactionId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteTransaction(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse({'message': 'Transação deletada com sucesso'});
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao deletar transação: ${e.toString()}',
      );
    }
  }

  Future<Response> handleGetFinancialSummary(Request request) async {
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
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para buscar resumo.');
        }
        therapistId = int.tryParse(therapistIdParam);
        if (therapistId == null) {
          return badRequestResponse('therapistId inválido');
        }
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem acessar resumo financeiro.',
        );
      }

      final startDateParam = request.url.queryParameters['startDate'];
      final endDateParam = request.url.queryParameters['endDate'];

      DateTime? startDate;
      if (startDateParam != null) {
        startDate = DateTime.tryParse(startDateParam);
      }

      DateTime? endDate;
      if (endDateParam != null) {
        endDate = DateTime.tryParse(endDateParam);
      }

      final summary = await _controller.getFinancialSummary(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );

      return successResponse(summary);
    } on FinancialException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao buscar resumo financeiro: ${e.toString()}',
      );
    }
  }
}


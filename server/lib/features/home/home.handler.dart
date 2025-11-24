import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/home/home.controller.dart';
import 'package:server/features/home/home.routes.dart';

class HomeHandler extends BaseHandler {
  HomeHandler(this._controller);

  final HomeController _controller;

  @override
  Router get router => configureHomeRoutes(this);

  Future<Response> handleGetSummary(Request request) async {
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária.');
      }

      DateTime? referenceDate;
      final dateParam = request.url.queryParameters['date'];
      if (dateParam != null) {
        referenceDate = DateTime.tryParse(dateParam);
        if (referenceDate == null) {
          return badRequestResponse('Parâmetro de data inválido.');
        }
      }

      late final int therapistId;
      int? accountContext = accountId;

      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse(
            'Conta de terapeuta não vinculada. Complete o perfil primeiro.',
          );
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistParam = request.url.queryParameters['therapistId'];
        if (therapistParam == null) {
          return badRequestResponse(
            'Informe o therapistId para consultar os dados.',
          );
        }

        final parsed = int.tryParse(therapistParam);
        if (parsed == null) {
          return badRequestResponse('therapistId inválido.');
        }

        therapistId = parsed;
        accountContext = therapistId;
      } else {
        return forbiddenResponse(
          'Somente terapeutas ou administradores podem acessar este recurso.',
        );
      }

      final summary = await _controller.getSummary(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountContext,
        referenceDate: referenceDate,
      );

      return successResponse(summary.toJson());
    } on HomeException catch (e) {
      AppLogger.error(e);
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse(
        'Erro ao carregar resumo da home: ${e.toString()}',
      );
    }
  }
}

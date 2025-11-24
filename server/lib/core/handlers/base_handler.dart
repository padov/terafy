import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Classe base abstrata para todos os handlers do projeto
///
/// Define métodos comuns e padrões para respostas HTTP padronizadas.
/// Todos os handlers devem estender esta classe.
abstract class BaseHandler {
  /// Router abstrato que cada handler deve implementar
  Router get router;

  /// Cria uma resposta de erro padronizada
  ///
  /// [message] - Mensagem de erro
  /// [statusCode] - Código HTTP de status (padrão: 400)
  ///
  /// Retorna uma Response com formato JSON padronizado:
  /// ```json
  /// {
  ///   "error": "mensagem de erro"
  /// }
  /// ```
  Response errorResponse(String message, {int statusCode = 400}) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Cria uma resposta de sucesso padronizada
  ///
  /// [data] - Dados a serem retornados (será convertido para JSON)
  /// [statusCode] - Código HTTP de status (padrão: 200)
  ///
  /// Retorna uma Response com formato JSON padronizado
  Response successResponse(dynamic data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Cria uma resposta de sucesso para criação de recursos (201 Created)
  ///
  /// [data] - Dados do recurso criado
  Response createdResponse(dynamic data) {
    return successResponse(data, statusCode: 201);
  }

  /// Cria uma resposta de não encontrado (404)
  ///
  /// [message] - Mensagem de erro (padrão: "Recurso não encontrado")
  Response notFoundResponse([String? message]) {
    return errorResponse(message ?? 'Recurso não encontrado', statusCode: 404);
  }

  /// Cria uma resposta de não autorizado (401)
  ///
  /// [message] - Mensagem de erro (padrão: "Não autorizado")
  Response unauthorizedResponse([String? message]) {
    return errorResponse(message ?? 'Não autorizado', statusCode: 401);
  }

  /// Cria uma resposta de acesso negado (403)
  ///
  /// [message] - Mensagem de erro (padrão: "Acesso negado")
  Response forbiddenResponse([String? message]) {
    return errorResponse(message ?? 'Acesso negado', statusCode: 403);
  }

  /// Cria uma resposta de erro interno do servidor (500)
  ///
  /// [message] - Mensagem de erro (padrão: "Erro interno do servidor")
  Response internalServerErrorResponse([String? message]) {
    return errorResponse(
      message ?? 'Erro interno do servidor',
      statusCode: 500,
    );
  }

  /// Cria uma resposta de requisição inválida (400)
  ///
  /// [message] - Mensagem de erro (padrão: "Requisição inválida")
  Response badRequestResponse([String? message]) {
    return errorResponse(message ?? 'Requisição inválida', statusCode: 400);
  }
}

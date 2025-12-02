import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'dart:convert';

/// Helpers para facilitar testes HTTP
class HttpTestHelpers {
  /// Cria um Request HTTP para testes
  static Request createRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? token,
  }) {
    final uri = Uri.parse('http://localhost$path');
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    return Request(method, uri, body: body != null ? jsonEncode(body) : null, headers: defaultHeaders);
  }

  /// Parseia resposta JSON como Map
  static Future<Map<String, dynamic>> parseJsonResponse(Response response) async {
    final body = await response.readAsString();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Parseia resposta JSON como List
  static Future<List<dynamic>> parseJsonListResponse(Response response) async {
    final body = await response.readAsString();
    return jsonDecode(body) as List<dynamic>;
  }

  /// Valida que a resposta é um erro com código específico
  static Future<void> expectErrorResponse(
    Response response,
    int expectedStatusCode,
    String? expectedErrorContains,
  ) async {
    expect(response.statusCode, expectedStatusCode);
    if (expectedErrorContains != null) {
      final body = await response.readAsString();
      expect(body.toLowerCase(), contains(expectedErrorContains.toLowerCase()));
    }
  }

  /// Valida que a resposta é sucesso com código específico
  static Future<Map<String, dynamic>> expectSuccessResponse(Response response, int expectedStatusCode) async {
    expect(response.statusCode, expectedStatusCode);
    return await parseJsonResponse(response);
  }
}

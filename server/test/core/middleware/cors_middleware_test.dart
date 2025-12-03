import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:server/core/middleware/cors_middleware.dart';

void main() {
  group('CORS Middleware', () {
    late Handler handler;

    setUp(() {
      // Handler simples que retorna 200 OK
      final innerHandler = (Request request) => Response.ok('ok');
      handler = corsMiddleware()(innerHandler);
    });

    test('OPTIONS request deve retornar 200 OK com headers CORS', () async {
      final request = Request('OPTIONS', Uri.parse('http://localhost/'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(response.headers['Access-Control-Allow-Origin'], equals('*'));
      expect(response.headers['Access-Control-Allow-Methods'], contains('GET, POST'));
      expect(response.headers['Access-Control-Allow-Headers'], contains('Content-Type'));
      expect(response.headers['Access-Control-Max-Age'], equals('86400'));
    });

    test('GET request deve retornar resposta original com headers CORS', () async {
      final request = Request('GET', Uri.parse('http://localhost/'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(await response.readAsString(), equals('ok'));

      // Verifica headers CORS
      expect(response.headers['Access-Control-Allow-Origin'], equals('*'));
      expect(response.headers['Access-Control-Allow-Methods'], isNotNull);
    });

    test('POST request deve retornar resposta original com headers CORS', () async {
      final request = Request('POST', Uri.parse('http://localhost/'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(response.headers['Access-Control-Allow-Origin'], equals('*'));
    });
  });
}

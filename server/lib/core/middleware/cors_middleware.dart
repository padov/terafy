import 'package:shelf/shelf.dart';

/// Middleware para habilitar CORS (Cross-Origin Resource Sharing)
/// Necessário para que aplicações web possam fazer requisições ao backend
///
/// Nota: CORS é uma política de segurança dos navegadores. Apps móveis (Android/iOS)
/// não são afetados por CORS, então adicionar este middleware não afeta apps nativos.
Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      // Se for uma requisição OPTIONS (preflight), retorna resposta imediatamente
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      // Processa a requisição normalmente
      final response = await handler(request);

      // Adiciona headers CORS à resposta
      return response.change(headers: _corsHeaders);
    };
  };
}

/// Headers CORS permitindo requisições de qualquer origem em desenvolvimento
/// Em produção, substitua '*' pela origem específica do seu app web
///
/// Exemplo para produção:
/// 'Access-Control-Allow-Origin': 'https://app.terafy.app.br'
final Map<String, String> _corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Em produção, use: 'https://app.terafy.app.br'
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400', // 24 horas
  'Access-Control-Allow-Credentials': 'true',
};

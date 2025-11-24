import 'dart:io';
import 'package:server/core/services/jwt_token_helper.dart';

/// Script para decodificar e visualizar um token JWT
///
/// Uso:
///   dart run bin/decode_token.dart <token>
///
/// Exemplo:
///   dart run bin/decode_token.dart eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Erro: Token não fornecido');
    print('');
    print('Uso: dart run bin/decode_token.dart <token>');
    print('');
    print('Exemplo:');
    print(
      '  dart run bin/decode_token.dart eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    );
    exit(1);
  }

  final token = args[0];

  print('🔍 Decodificando token JWT...\n');
  print(
    'Token: ${token.substring(0, token.length > 50 ? 50 : token.length)}...\n',
  );

  // Decodifica o token usando o model
  final jwtToken = JwtTokenHelper.decode(token);

  if (jwtToken == null) {
    print('❌ Erro: Token inválido ou não pôde ser decodificado');
    exit(1);
  }

  print('✅ Token decodificado com sucesso!\n');
  print('═' * 60);
  print('📋 PAYLOAD DO TOKEN (Claims)');
  print('═' * 60);
  print('');

  // Exibe os claims de forma organizada usando o model
  print('👤 Informações do Usuário:');
  print('   User ID (sub):     ${jwtToken.userId}');
  print('   Email:             ${jwtToken.email}');
  print('   Role:              ${jwtToken.role}');
  print('');

  print('🔗 Informações da Conta:');
  print(
    '   Account Type:      ${jwtToken.accountType ?? 'null (não vinculado)'}',
  );
  print(
    '   Account ID:        ${jwtToken.accountId ?? 'null (não vinculado)'}',
  );
  if (jwtToken.hasTherapistAccount) {
    print('   Therapist ID:      ${jwtToken.therapistId}');
  }
  if (jwtToken.hasPatientAccount) {
    print('   Patient ID:        ${jwtToken.patientId}');
  }
  print('');

  print('⏰ Informações de Tempo:');
  print('   Emitido em (iat):  ${jwtToken.issuedAtDateTime}');
  print('   Expira em (exp):   ${jwtToken.expirationDateTime}');
  print(
    '   Status:            ${jwtToken.isExpired ? '❌ EXPIRADO' : '✅ Válido'}',
  );
  if (!jwtToken.isExpired) {
    final remaining = jwtToken.timeUntilExpiration;
    print(
      '   Tempo restante:    ${remaining.inDays} dias, ${remaining.inHours % 24} horas',
    );
  }
  print('');

  print('═' * 60);
  print('📊 ESTRUTURA COMPLETA DO TOKEN');
  print('═' * 60);
  print('');

  // Exibe todos os claims usando toMap
  final claimsJson = jwtToken.toMap();
  claimsJson.forEach((key, value) {
    print('   $key: $value');
  });
  print('');

  // Valida o token
  print('═' * 60);
  print('🔐 VALIDAÇÃO DO TOKEN');
  print('═' * 60);
  print('');

  final validatedToken = JwtTokenHelper.validateAndParse(token);
  if (validatedToken != null) {
    print('✅ Token válido e assinado corretamente!');
    print('   O token pode ser usado para autenticação.');
  } else {
    print('❌ Token inválido ou expirado!');
    print('   O token não pode ser usado para autenticação.');
  }
  print('');
}

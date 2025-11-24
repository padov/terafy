// import 'dart:io';

// import 'package:basic_utils/basic_utils.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// // String signMessage(String message, String privateKey) {
// //   final keyBytes = utf8.encode(privateKey);
// //   final hmacSha256 = Hmac(sha256, keyBytes); // HMAC-SHA256
// //   final digest = hmacSha256.convert(utf8.encode(message));
// //   return base64.encode(digest.bytes);

// Future<void> loadCertificateAndKey() async {
//   try {
//     // Carregar o certificado
//     // String certPem = await rootBundle.loadString("assets/certificates/cert.pem");

//     // Carregar a chave privada
//     // String keyPem = await rootBundle.loadString("assets/certificates/cert.pem");

//     // Processamento e uso
//     // X509CertificateData certData = X509Utils.x509CertificateFromPem(certPem);
//     // RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPem(keyPem);

//     // Use o certificado e a chave privada conforme necessário
//     print('Certificado carregado com sucesso');
//   } catch (e) {
//     print('Erro ao carregar o certificado ou a chave privada: $e');
//     // Lidar com o erro apropriadamente, talvez falhar com uma mensagem clara
//   }
// }

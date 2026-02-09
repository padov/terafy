import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/common.dart';
import 'package:server/core/middleware/auth_middleware.dart';

import 'package:server/core/services/openai_service.dart';
import 'package:server/features/ai_config/models/therapist_profile_model.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:shelf/shelf.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class SessionAIController {
  final SessionRepository _sessionRepository;
  final PatientRepository _patientRepository;
  final TherapistRepository _therapistRepository;
  final OpenAIService _openAIService;

  SessionAIController(this._sessionRepository, this._patientRepository, this._therapistRepository, this._openAIService);

  Future<Response> handleAnalyzeAudio(Request request, String sessionIdStr) async {
    try {
      if (request.mimeType != 'multipart/form-data') {
        return Response.badRequest(body: 'Request must be multipart');
      }

      final sessionId = int.tryParse(sessionIdStr);
      if (sessionId == null) {
        return Response.badRequest(body: 'Invalid Session ID');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null) {
        return Response.forbidden('User not authenticated');
      }

      // 1. Validar Sessão
      final session = await _sessionRepository.getSessionById(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (session == null) {
        return Response.notFound('Session not found');
      }

      final contentType = MediaType.parse(request.headers['content-type']!);
      final boundary = contentType.parameters['boundary'];
      if (boundary == null) {
        return Response.badRequest(body: 'Missing boundary');
      }

      File? audioFile;
      String? originalFilename;

      final transformer = MimeMultipartTransformer(boundary);
      final parts = request.read().cast<List<int>>().transform(transformer);

      await for (final part in parts) {
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition != null) {
          final disposition = HeaderValue.parse(contentDisposition);
          if (disposition.parameters['name'] == 'audio') {
            originalFilename = disposition.parameters['filename'];

            if (originalFilename == null) continue;

            // Criar diretório de uploads se não existir
            final uploadDir = Directory('uploads');
            if (!await uploadDir.exists()) {
              await uploadDir.create();
            }

            final extension = p.extension(originalFilename);
            final filename = 'session_${sessionId}_${DateTime.now().millisecondsSinceEpoch}$extension';
            final filePath = p.join(uploadDir.path, filename);

            audioFile = File(filePath);
            final sink = audioFile.openWrite();
            await sink.addStream(
              part,
            ); // MimeMultipart IS a stream of bytes? No, MimeMultipart extends Stream<List<int>>
            await sink.close();
            break;
          }
        }
      }

      if (audioFile == null) {
        return Response.badRequest(body: 'No audio file uploaded');
      }

      try {
        // 3. Obter contextos (Paciente e Terapeuta)
        final patient = await _patientRepository.getPatientById(
          session.patientId,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: userRole == 'admin',
        );

        if (patient == null) {
          throw Exception('Patient not found');
        }

        final therapist = await _therapistRepository.getTherapistById(
          session.therapistId,
          userId: userId,
          userRole: userRole,
          // bypassRLS: true // Assumindo que o usuário logado pode ver o perfil
        );

        if (therapist == null) {
          throw Exception('Therapist not found');
        }

        TherapistProfileModel profile = const TherapistProfileModel();
        if (therapist.aiConfig != null) {
          profile = TherapistProfileModel.fromJson(therapist.aiConfig!);
        }

        // 4. Transcrever
        final transcription = await _openAIService.transcribeAudio(audioFile);

        // 5. Analisar
        final analysisJson = await _openAIService.analyzeSession(
          transcription: transcription,
          therapistProfile: profile,
          patientName: patient.fullName,
        );

        // 6. Atualizar attachments da sessão com o caminho do arquivo
        final currentAttachments = List<String>.from(session.attachments);
        // Salvamos o caminho relativo
        currentAttachments.add('uploads/${p.basename(audioFile.path)}');

        final updatedSession = session.copyWith(attachments: currentAttachments, updatedAt: DateTime.now());

        await _sessionRepository.updateSession(
          sessionId: sessionId,
          session: updatedSession,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: userRole == 'admin',
        );

        // 7. Retornar JSON sugerido + Transcrição + URL do áudio
        final responseData = {
          ...analysisJson,
          'transcription': transcription,
          'audioUrl': 'uploads/${p.basename(audioFile.path)}',
        };

        print('=== ANALYSIS RESULT ===');
        print(jsonEncode(responseData));
        print('=======================');

        return Response.ok(jsonEncode(responseData), headers: {'content-type': 'application/json'});
      } catch (e, stack) {
        AppLogger.error('Error processing audio session: $e', stack);
        // Tenta deletar o arquivo em caso de erro no processamento
        if (audioFile != null && await audioFile.exists()) {
          // await audioFile.delete(); // Opcional: manter para debug ou deletar
        }
        return Response.internalServerError(body: 'Error processing audio: $e');
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return Response.internalServerError(body: 'Internal Server Error');
    }
  }
}

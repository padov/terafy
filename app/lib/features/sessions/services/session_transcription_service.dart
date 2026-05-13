import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'speech_to_text_web_bridge.dart';

/// Serviço de transcrição de áudio em tempo real usando as APIs nativas do dispositivo.
/// iOS/Android: Plugin SpeechToText   Web: JavaScript Interop Puro nativo
class SessionTranscriptionService {
  final _speechDesktop = SpeechToText();
  final _speechWeb = WebSpeechService();

  bool _isInitialized = false;

  // Controle de auto-restart (essencial para web/longas durações)
  bool _shouldBeListening = false;
  void Function(String)? _lastOnResult;
  void Function()? _lastOnChunkDone;

  /// Verifica se o STT está disponível no dispositivo
  bool get isAvailable => _isInitialized;

  /// Inicializa o serviço e solicita permissão de microfone.
  Future<bool> init() async {
    try {
      if (kIsWeb) {
        _isInitialized = await _speechWeb.init();
      } else {
        _isInitialized = await _speechDesktop.initialize(
          onError: (error) {
            print('STT OnError: \${error.errorMsg} - Permanent: \${error.permanent}');
          },
          onStatus: _handleStatus,
          debugLogging: true,
        );
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('Erro na init do STT Wrapper: $e');
      return false;
    }
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_shouldBeListening) {
        _lastOnChunkDone?.call();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_shouldBeListening) {
            _startInternal();
          }
        });
      }
    }
  }

  Future<void> startListening({required void Function(String text) onResult, void Function()? onChunkDone}) async {
    if (!_isInitialized) return;

    _shouldBeListening = true;
    _lastOnResult = onResult;
    _lastOnChunkDone = onChunkDone;

    await _startInternal();
  }

  Future<void> _startInternal() async {
    if (kIsWeb) {
      if (_speechWeb.isListening) return;
      await _speechWeb.startListening(
        onResult: (res) => _lastOnResult?.call(res),
        onChunkDone: () => _handleStatus('done'),
      );
    } else {
      if (_speechDesktop.isListening) return;
      await _speechDesktop.listen(
        onResult: (result) {
          _lastOnResult?.call(result.recognizedWords);
        },
        localeId: 'pt_BR',
        listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation, cancelOnError: false),
        pauseFor: const Duration(seconds: 30),
      );
    }
  }

  Future<void> stopListening() async {
    _shouldBeListening = false;
    if (kIsWeb) {
      await _speechWeb.stopListening();
    } else {
      await _speechDesktop.stop();
    }
  }

  Future<void> cancel() async {
    _shouldBeListening = false;
    if (kIsWeb) {
      await _speechWeb.cancel();
    } else {
      await _speechDesktop.cancel();
    }
  }

  bool get isListening => _shouldBeListening;

  void dispose() {
    _shouldBeListening = false;
    if (kIsWeb) {
      _speechWeb.dispose();
    } else {
      _speechDesktop.cancel();
    }
  }
}

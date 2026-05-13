import 'dart:async';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';

@JS('window.webkitSpeechRecognition')
external JSFunction? get _webkitSpeech;

@JS('window.SpeechRecognition')
external JSFunction? get _speech;

extension type WebSpeechExt(JSObject _) implements JSObject {
  external set continuous(JSBoolean value);
  external set interimResults(JSBoolean value);
  external set lang(JSString value);
  external set onresult(JSFunction value);
  external set onend(JSFunction value);
  external set onerror(JSFunction value);
  external void start();
  external void stop();
  external void abort();
}

extension type SpeechEvent(JSObject _) implements JSObject {
  external SpeechResultList get results;
  external JSString? get error;
}

extension type SpeechResultList(JSObject _) implements JSObject {
  external JSNumber get length;
  external SpeechResult item(int index);
}

extension type SpeechResult(JSObject _) implements JSObject {
  external SpeechAlternative item(int index);
}

extension type SpeechAlternative(JSObject _) implements JSObject {
  external JSString get transcript;
}

class WebSpeechService {
  WebSpeechExt? _recognition;
  bool _isInit = false;
  bool _shouldBeListening = false;

  void Function(String)? _onResult;
  void Function()? _onChunkDone;

  bool get isAvailable => _isInit;
  bool get isListening => _shouldBeListening;

  Future<bool> init() async {
    try {
      if (_speech != null) {
        _recognition = WebSpeechExt(_speech!.callAsConstructor<JSObject>());
      } else if (_webkitSpeech != null) {
        _recognition = WebSpeechExt(_webkitSpeech!.callAsConstructor<JSObject>());
      }

      if (_recognition != null) {
        _recognition!.continuous = true.toJS;
        _recognition!.interimResults = true.toJS;
        _recognition!.lang = 'pt-BR'.toJS;

        _recognition!.onresult = _handleResult.toJS;
        _recognition!.onend = _handleEnd.toJS;
        _recognition!.onerror = _handleError.toJS;

        _isInit = true;
        return true;
      }
    } catch (e) {
      debugPrint('Falha Crítica Instanciando JS Speech API: $e');
    }
    return false;
  }

  void _handleResult(SpeechEvent event) {
    if (!_shouldBeListening) return;
    try {
      final results = event.results;
      final length = results.length.toDartInt;

      String transcript = '';
      for (var i = 0; i < length; i++) {
        final result = results.item(i);
        final finalAlternative = result.item(0);
        transcript += finalAlternative.transcript.toDart;
      }
      _onResult?.call(transcript);
    } catch (e) {
      debugPrint('Erro processando evento de fala Web: $e');
    }
  }

  void _handleEnd(JSAny? event) {
    if (_shouldBeListening) {
      _onChunkDone?.call();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_shouldBeListening) {
          _startInternal();
        }
      });
    }
  }

  void _handleError(SpeechEvent event) {
    final errStr = event.error?.toDart ?? 'Desconhecido';
    debugPrint('Web Speech Error disparado: $errStr');
  }

  Future<void> startListening({required void Function(String) onResult, void Function()? onChunkDone}) async {
    if (!_isInit || _recognition == null) return;
    _shouldBeListening = true;
    _onResult = onResult;
    _onChunkDone = onChunkDone;
    _startInternal();
  }

  void _startInternal() {
    try {
      _recognition?.start();
    } catch (_) {}
  }

  Future<void> stopListening() async {
    _shouldBeListening = false;
    try {
      _recognition?.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    _shouldBeListening = false;
    try {
      _recognition?.abort();
    } catch (_) {}
  }

  void dispose() {
    cancel();
  }
}

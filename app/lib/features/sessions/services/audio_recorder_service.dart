import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialised = false;
  final Logger _logger = Logger('AudioRecorderService');

  bool get isRecording => _recorder.isRecording;

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    try {
      await _recorder.openRecorder();
      _isRecorderInitialised = true;
    } catch (e) {
      _logger.severe('Failed to open recorder', e);
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialised) return;

    String path;
    Codec codec;

    if (kIsWeb) {
      path = 'session_audio_${DateTime.now().millisecondsSinceEpoch}.webm';
      codec = Codec.opusWebM;
    } else {
      final tempDir = await getTemporaryDirectory();
      path = p.join(tempDir.path, 'session_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
      codec = Codec.aacMP4;
    }

    await _recorder.startRecorder(toFile: path, codec: codec);
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialised) return null;
    return await _recorder.stopRecorder();
  }

  Future<void> dispose() async {
    if (_isRecorderInitialised) {
      await _recorder.closeRecorder();
      _isRecorderInitialised = false;
    }
  }
}

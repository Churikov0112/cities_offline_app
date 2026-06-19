import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static const timeout = Duration(seconds: 20);
  static const pause = Duration(seconds: 2);

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize();
    return _initialized;
  }

  Future<String?> listen({
    Duration timeout = SpeechService.timeout,
    Duration pause = SpeechService.pause,
    String? localeId,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return null;
    }

    final completer = Completer<String?>();
    Timer? cancelTimer;
    Timer? speechEndTimer;
    String lastWords = '';

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          cancelTimer?.cancel();
          speechEndTimer?.cancel();
          if (!completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
          return;
        }

        if (result.recognizedWords.isNotEmpty) {
          lastWords = result.recognizedWords;
          speechEndTimer?.cancel();
          speechEndTimer = Timer(pause, () {
            cancelTimer?.cancel();
            _stt.stop();
            if (!completer.isCompleted) {
              completer.complete(lastWords);
            }
          });
        }
      },
      localeId: localeId,
      listenFor: timeout,
      pauseFor: timeout,
    );

    cancelTimer = Timer(timeout, () {
      speechEndTimer?.cancel();
      _stt.stop();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<void> stop() async {
    await _stt.stop();
  }

  Future<void> cancel() async {
    await _stt.cancel();
  }

  Future<String> get currentLocale async {
    final locale = await _stt.systemLocale();
    return locale?.localeId ?? 'en_US';
  }

  bool get isListening => _stt.isListening;
  bool get isAvailable => _initialized;

  Future<List<stt.LocaleName>> get locales async => _stt.locales();
}

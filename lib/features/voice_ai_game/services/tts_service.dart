import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  Completer<void>? _speakCompleter;

  Future<bool> initialize() async {
    _tts.setCompletionHandler(() {
      _speakCompleter?.complete();
      _speakCompleter = null;
    });
    _tts.setErrorHandler((msg) {
      _speakCompleter?.complete();
      _speakCompleter = null;
    });
    return true;
  }

  Future<void> speak(String text) async {
    await stop();
    _speakCompleter = Completer<void>();
    await _tts.speak(text);
    await _speakCompleter!.future;
  }

  Future<void> stop() async {
    _speakCompleter?.complete();
    _speakCompleter = null;
    await _tts.stop();
  }

  Future<void> setLanguage(String lang) async {
    await _tts.setLanguage(lang);
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  void dispose() {
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((_) {});
    _speakCompleter?.complete();
    _speakCompleter = null;
  }
}

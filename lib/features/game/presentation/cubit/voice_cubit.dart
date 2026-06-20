import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../voice_ai_game/services/command_parser.dart';
import '../../../voice_ai_game/services/intent_lexemes.dart';
import '../../../voice_ai_game/services/speech_service.dart';
import '../../../voice_ai_game/services/tts_service.dart';

enum VoicePhase { idle, speaking, listening, processing }

class VoiceState {
  final VoicePhase phase;
  final String statusText;

  const VoiceState({
    this.phase = VoicePhase.idle,
    this.statusText = '',
  });

  VoiceState copyWith({VoicePhase? phase, String? statusText}) {
    return VoiceState(
      phase: phase ?? this.phase,
      statusText: statusText ?? this.statusText,
    );
  }
}

class VoiceCubit extends Cubit<VoiceState> {
  final TtsService _tts;
  final SpeechService _speech;
  final CommandParser _parser;
  VoiceCubit({
    required TtsService tts,
    required SpeechService speech,
    required CommandParser parser,
  }) : _tts = tts,
       _speech = speech,
       _parser = parser,
       super(const VoiceState());

  void setPhase(VoicePhase phase) => emit(state.copyWith(phase: phase));

  void setStatusText(String text) => emit(state.copyWith(statusText: text));

  Future<bool> initialize() async {
    final ttsOk = await _tts.initialize();
    final speechOk = await _speech.initialize();
    return ttsOk && speechOk;
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    emit(state.copyWith(phase: VoicePhase.speaking));
    await _tts.speak(text);
    emit(state.copyWith(phase: VoicePhase.idle));
  }

  Future<VoiceCommand> listen() async {
    emit(state.copyWith(phase: VoicePhase.listening));

    final recognized = await _speech.listen();

    if (recognized == null || recognized.trim().isEmpty) {
      emit(state.copyWith(phase: VoicePhase.idle));
      return const VoiceCommand(intent: VoiceIntent.unknown, rawText: '');
    }

    emit(state.copyWith(phase: VoicePhase.processing));

    final command = await _parser.parse(recognized);

    emit(state.copyWith(phase: VoicePhase.idle));
    return command;
  }

  Future<void> stop() async {
    await _speech.stop();
    await _tts.stop();
    emit(state.copyWith(phase: VoicePhase.idle));
  }

  Future<void> cancel() async {
    await _speech.cancel();
    await _tts.stop();
    emit(state.copyWith(phase: VoicePhase.idle));
  }
}

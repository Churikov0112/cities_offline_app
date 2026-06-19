import 'package:flutter_bloc/flutter_bloc.dart';
import 'voice_game_state.dart';

class VoiceGameCubit extends Cubit<VoiceGameState> {
  VoiceGameCubit() : super(const VoiceGameState());

  void setPhase(VoicePhase phase) {
    emit(state.copyWith(phase: phase));
  }

  void setStatusText(String text) {
    emit(state.copyWith(statusText: text));
  }
}

enum VoicePhase { ready, speaking, listening, processing, thinking, gameOver }

class VoiceGameState {
  final VoicePhase phase;
  final String statusText;

  const VoiceGameState({
    this.phase = VoicePhase.ready,
    this.statusText = '',
  });

  VoiceGameState copyWith({
    VoicePhase? phase,
    String? statusText,
  }) {
    return VoiceGameState(
      phase: phase ?? this.phase,
      statusText: statusText ?? this.statusText,
    );
  }
}

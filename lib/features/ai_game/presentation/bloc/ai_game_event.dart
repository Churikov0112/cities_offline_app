part of 'ai_game_bloc.dart';

sealed class AiGameEvent {
  const AiGameEvent();
}

class AiSessionCreated extends AiGameEvent {
  final AiGameRules rules;
  final AiDifficultyConfig difficulty;

  const AiSessionCreated({
    required this.rules,
    required this.difficulty,
  });
}

class AiCitySubmitted extends AiGameEvent {
  final String sessionId;
  final String cityName;

  const AiCitySubmitted({
    required this.sessionId,
    required this.cityName,
  });
}

class AiRulesUpdated extends AiGameEvent {
  final String sessionId;
  final AiGameRules rules;

  const AiRulesUpdated({
    required this.sessionId,
    required this.rules,
  });
}

class AiDifficultyUpdated extends AiGameEvent {
  final String sessionId;
  final AiDifficultyConfig difficulty;

  const AiDifficultyUpdated({
    required this.sessionId,
    required this.difficulty,
  });
}

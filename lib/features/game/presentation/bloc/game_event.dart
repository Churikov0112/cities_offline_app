import '../../../ai_game/domain/models/ai_difficulty_config.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/game_session.dart';

sealed class GameEvent {
  const GameEvent();
}

class GameSessionCreated extends GameEvent {
  final String id;
  final GameRules rules;
  final OpponentType opponent;
  final AiDifficultyConfig? difficulty;
  final bool isVoiceEnabled;

  const GameSessionCreated({
    required this.id,
    required this.rules,
    required this.opponent,
    this.difficulty,
    this.isVoiceEnabled = false,
  });
}

class GameCitySubmitted extends GameEvent {
  final String sessionId;
  final String cityName;

  const GameCitySubmitted({
    required this.sessionId,
    required this.cityName,
  });
}

class GameRulesUpdated extends GameEvent {
  final String sessionId;
  final GameRules rules;

  const GameRulesUpdated({
    required this.sessionId,
    required this.rules,
  });
}

class GameOpponentUpdated extends GameEvent {
  final String sessionId;
  final OpponentType opponent;
  final AiDifficultyConfig? difficulty;

  const GameOpponentUpdated({
    required this.sessionId,
    required this.opponent,
    this.difficulty,
  });
}

class GameDifficultyUpdated extends GameEvent {
  final String sessionId;
  final AiDifficultyConfig difficulty;

  const GameDifficultyUpdated({
    required this.sessionId,
    required this.difficulty,
  });
}

class GameVoiceToggled extends GameEvent {
  final String sessionId;
  final bool isVoiceEnabled;

  const GameVoiceToggled({
    required this.sessionId,
    required this.isVoiceEnabled,
  });
}

class GameHintRequested extends GameEvent {
  final String sessionId;

  const GameHintRequested({required this.sessionId});
}

class GameSurrenderRequested extends GameEvent {
  final String sessionId;

  const GameSurrenderRequested({required this.sessionId});
}

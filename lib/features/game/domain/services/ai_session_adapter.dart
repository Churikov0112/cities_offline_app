import '../../../ai_game/domain/models/ai_difficulty_config.dart';
import '../../../ai_game/domain/models/ai_fatigue_state.dart';
import '../../../ai_game/domain/models/ai_game_rules.dart';
import '../../../ai_game/domain/models/ai_game_session.dart';
import '../../../ai_game/domain/models/ai_turn.dart';
import '../models/game_rules.dart';
import '../models/game_session.dart';
import '../models/game_turn.dart';

AiGameSession toAiGameSession(GameSession session) {
  return AiGameSession(
    id: session.id,
    createdAt: session.createdAt,
    updatedAt: session.updatedAt,
    rules: _toAiGameRules(session.rules),
    currentDifficulty: session.ai?.currentDifficulty ??
        const AiDifficultyConfig.medium(),
    difficultyFloor: session.ai?.difficultyFloor ??
        const AiDifficultyConfig.medium(),
    fatigue: session.ai?.fatigue ?? const AiFatigueState.initial(),
    turns: session.turns.map(_toAiTurn).toList(),
    status: AiGameStatus.values.firstWhere(
      (s) => s.name == session.status.name,
      orElse: () => AiGameStatus.active,
    ),
    winner: session.winner == null
        ? null
        : AiGameWinner.values.firstWhere(
            (w) => w.name == session.winner!.name,
            orElse: () => AiGameWinner.user,
          ),
    isAiThinking: session.ai?.isAiThinking ?? false,
  );
}

AiGameRules _toAiGameRules(GameRules rules) {
  return AiGameRules(
    allowedTypes: rules.allowedTypeStrings,
    allowHistoricalNames: rules.allowHistoricalNames,
    minPopulation: rules.minPopulation,
    preferredLanguage: rules.preferredLanguage,
    allowedCountryCodes: rules.allowedCountryCodes,
  );
}

AiTurn _toAiTurn(GameTurn turn) {
  return AiTurn(
    actor: AiTurnActor.values.firstWhere(
      (a) => a.name == turn.actor.name,
      orElse: () => AiTurnActor.user,
    ),
    input: turn.input,
    status: AiTurnStatus.values.firstWhere(
      (s) => s.name == turn.status.name,
      orElse: () => AiTurnStatus.rejected,
    ),
    locality: turn.locality,
    rejectReason: turn.rejectReason == null
        ? null
        : AiTurnRejectReason.values.firstWhere(
            (r) => r.name == turn.rejectReason!.name,
            orElse: () => AiTurnRejectReason.notFound,
          ),
    expectedStartLetter: turn.expectedStartLetter,
    duplicateMatchedName: turn.duplicateMatchedName,
  );
}

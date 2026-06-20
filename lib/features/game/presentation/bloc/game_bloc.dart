import 'dart:math';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../ai_game/domain/models/ai_difficulty_config.dart';
import '../../../ai_game/domain/models/ai_fatigue_state.dart';
import '../../../ai_game/domain/services/ai_move_service.dart';
import '../../domain/models/ai_state.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_turn.dart';
import '../../domain/services/ai_session_adapter.dart';
import '../../domain/services/hint_service.dart';
import '../../domain/services/turn_validator.dart';
import 'game_event.dart';

@singleton
class GameBloc extends HydratedBloc<GameEvent, GameState> {
  final TurnValidator _turnValidator;
  final HintService _hintService;
  final AiMoveService _aiMoveService;

  GameBloc({
    required TurnValidator turnValidator,
    required HintService hintService,
    required AiMoveService aiMoveService,
  }) : _turnValidator = turnValidator,
       _hintService = hintService,
       _aiMoveService = aiMoveService,
       super(const GameState.initial()) {
    on<GameSessionCreated>(_onSessionCreated);
    on<GameCitySubmitted>(_onCitySubmitted);
    on<GameRulesUpdated>(_onRulesUpdated);
    on<GameOpponentUpdated>(_onOpponentUpdated);
    on<GameDifficultyUpdated>(_onDifficultyUpdated);
    on<GameVoiceToggled>(_onVoiceToggled);
    on<GameHintRequested>(_onHintRequested);
    on<GameSurrenderRequested>(_onSurrenderRequested);
  }

  Future<void> _onSessionCreated(
    GameSessionCreated event,
    Emitter<GameState> emit,
  ) async {
    final now = DateTime.now();
    final session = GameSession(
      id: event.id,
      createdAt: now,
      updatedAt: now,
      rules: event.rules,
      opponent: event.opponent,
      status: GameStatus.active,
      winner: null,
      score: 0,
      turns: const [],
      ai: event.opponent == OpponentType.ai
          ? _createAiState(event.difficulty)
          : null,
      isVoiceEnabled: event.isVoiceEnabled,
    );
    emit(state.upsertSession(session));
  }

  Future<void> _onRulesUpdated(
    GameRulesUpdated event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) return;

    emit(
      state.upsertSession(
        session.copyWith(
          rules: event.rules,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onOpponentUpdated(
    GameOpponentUpdated event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) return;

    emit(
      state.upsertSession(
        session.copyWith(
          opponent: event.opponent,
          ai: event.opponent == OpponentType.ai
              ? _createAiState(event.difficulty)
              : null,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onDifficultyUpdated(
    GameDifficultyUpdated event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || session.ai == null) return;

    emit(
      state.upsertSession(
        session.copyWith(
          ai: session.ai!.copyWith(
            currentDifficulty: event.difficulty,
            difficultyFloor: event.difficulty,
          ),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onVoiceToggled(
    GameVoiceToggled event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) return;

    emit(
      state.upsertSession(
        session.copyWith(
          isVoiceEnabled: event.isVoiceEnabled,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onCitySubmitted(
    GameCitySubmitted event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || session.status == GameStatus.finished) return;
    if (session.opponent == OpponentType.ai &&
        (session.ai?.isAiThinking ?? false)) {
      return;
    }

    final userTurn = await _turnValidator.validate(
      session,
      event.cityName,
      actor: GameTurnActor.user,
    );
    final sessionWithUserTurn = session.withTurn(userTurn);
    emit(state.upsertSession(sessionWithUserTurn.copyWith(
      updatedAt: DateTime.now(),
    )));

    if (userTurn.status != GameTurnStatus.accepted) return;
    if (session.opponent != OpponentType.ai) return;

    final aiThinkingSession = sessionWithUserTurn.copyWith(
      ai: sessionWithUserTurn.ai?.copyWith(isAiThinking: true),
    );
    emit(state.upsertSession(aiThinkingSession));

    final aiResult = await _aiMoveService.chooseMove(
      toAiGameSession(aiThinkingSession),
    );
    final nextFatigue = aiThinkingSession.ai!.fatigue.advance(
      aiThinkingSession.ai!.currentDifficulty.fatigueGrowthPerMove,
    );

    if (aiResult.surrendered) {
      emit(
        state.upsertSession(
          aiThinkingSession
              .withTurn(
                const GameTurn(
                  actor: GameTurnActor.ai,
                  input: '',
                  status: GameTurnStatus.surrendered,
                ),
              )
              .copyWith(
                ai: aiThinkingSession.ai!.copyWith(
                  fatigue: nextFatigue,
                  isAiThinking: false,
                ),
                status: GameStatus.finished,
                winner: GameWinner.user,
                updatedAt: DateTime.now(),
              ),
        ),
      );
      return;
    }

    final aiTurn = aiResult.turn!;
    emit(
      state.upsertSession(
        aiThinkingSession
            .withTurn(
              GameTurn(
                actor: GameTurnActor.ai,
                input: aiTurn.input,
                status: GameTurnStatus.accepted,
                locality: aiTurn.locality,
              ),
            )
            .copyWith(
              ai: aiThinkingSession.ai!.copyWith(
                fatigue: nextFatigue,
                isAiThinking: false,
              ),
              updatedAt: DateTime.now(),
            ),
      ),
    );
  }

  Future<void> _onHintRequested(
    GameHintRequested event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || session.status == GameStatus.finished) return;
    if (session.opponent == OpponentType.ai &&
        (session.ai?.isAiThinking ?? false)) {
      return;
    }

    if (session.opponent == OpponentType.ai) {
      emit(
        state.upsertSession(
          session.copyWith(
            ai: session.ai!.copyWith(isAiThinking: true),
          ),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final hintLocality = await _hintService.pickHint(session);

    if (hintLocality == null) {
      if (session.opponent == OpponentType.ai) {
        emit(
          state.upsertSession(
            session.copyWith(
              ai: session.ai!.copyWith(isAiThinking: false),
            ),
          ),
        );
      }
      return;
    }

    final hintTurn = GameTurn(
      actor: GameTurnActor.user,
      input: hintLocality.matchedName,
      status: GameTurnStatus.accepted,
      locality: hintLocality,
    );

    final sessionWithHint = session.withTurn(hintTurn);
    emit(state.upsertSession(sessionWithHint.copyWith(
      updatedAt: DateTime.now(),
    )));

    if (session.opponent != OpponentType.ai) return;

    await Future.delayed(const Duration(seconds: 1));

    emit(
      state.upsertSession(
        sessionWithHint.copyWith(
          ai: sessionWithHint.ai!.copyWith(isAiThinking: true),
        ),
      ),
    );

    final aiResult = await _aiMoveService.chooseMove(
      toAiGameSession(sessionWithHint),
    );
    final nextFatigue = sessionWithHint.ai!.fatigue.advance(
      sessionWithHint.ai!.currentDifficulty.fatigueGrowthPerMove,
    );

    if (aiResult.surrendered) {
      emit(
        state.upsertSession(
          sessionWithHint
              .withTurn(
                const GameTurn(
                  actor: GameTurnActor.ai,
                  input: '',
                  status: GameTurnStatus.surrendered,
                ),
              )
              .copyWith(
                ai: sessionWithHint.ai!.copyWith(
                  fatigue: nextFatigue,
                  isAiThinking: false,
                ),
                status: GameStatus.finished,
                winner: GameWinner.user,
                updatedAt: DateTime.now(),
              ),
        ),
      );
      return;
    }

    final aiTurn = aiResult.turn!;
    emit(
      state.upsertSession(
        sessionWithHint
            .withTurn(
              GameTurn(
                actor: GameTurnActor.ai,
                input: aiTurn.input,
                status: GameTurnStatus.accepted,
                locality: aiTurn.locality,
              ),
            )
            .copyWith(
              ai: sessionWithHint.ai!.copyWith(
                fatigue: nextFatigue,
                isAiThinking: false,
              ),
              updatedAt: DateTime.now(),
            ),
      ),
    );
  }

  Future<void> _onSurrenderRequested(
    GameSurrenderRequested event,
    Emitter<GameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || session.status == GameStatus.finished) return;

    emit(
      state.upsertSession(
        session.copyWith(
          status: GameStatus.finished,
          winner: session.opponent == OpponentType.ai
              ? GameWinner.ai
              : null,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  AiState _createAiState(AiDifficultyConfig? difficulty) {
    return AiState(
      currentDifficulty: difficulty ?? const AiDifficultyConfig.medium(),
      difficultyFloor: difficulty ?? const AiDifficultyConfig.medium(),
      fatigue: const AiFatigueState.initial(),
      isAiThinking: false,
    );
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'game_${now}_$random';
  }

  @override
  GameState? fromJson(Map<String, dynamic> json) {
    return GameState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(GameState state) {
    return state.toJson();
  }
}

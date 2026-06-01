import 'dart:math';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../mediator/domain/repos/cities_repository.dart';
import '../../../mediator/domain/utils/utils.dart';
import '../../domain/models/ai_difficulty_config.dart';
import '../../domain/models/ai_fatigue_state.dart';
import '../../domain/models/ai_game_rules.dart';
import '../../domain/models/ai_game_session.dart';
import '../../domain/models/ai_game_state.dart';
import '../../domain/models/ai_turn.dart';
import '../../domain/services/ai_move_service.dart';

part 'ai_game_event.dart';

@singleton
class AiGameBloc extends HydratedBloc<AiGameEvent, AiGameState> {
  final CitiesRepository _citiesRepository;
  final AiMoveService _aiMoveService;

  AiGameBloc({
    required CitiesRepository citiesRepository,
    required AiMoveService aiMoveService,
  }) : _citiesRepository = citiesRepository,
       _aiMoveService = aiMoveService,
       super(const AiGameState.initial()) {
    on<AiSessionCreated>(_onSessionCreated);
    on<AiCitySubmitted>(_onCitySubmitted);
    on<AiRulesUpdated>(_onRulesUpdated);
    on<AiDifficultyUpdated>(_onDifficultyUpdated);
  }

  Future<void> _onSessionCreated(
    AiSessionCreated event,
    Emitter<AiGameState> emit,
  ) async {
    final now = DateTime.now();
    final session = AiGameSession(
      id: _generateId(),
      createdAt: now,
      updatedAt: now,
      rules: event.rules,
      currentDifficulty: event.difficulty,
      difficultyFloor: event.difficulty,
      fatigue: const AiFatigueState.initial(),
      turns: const [],
      status: AiGameStatus.active,
      winner: null,
      isAiThinking: false,
    );
    emit(state.upsertSession(session));
  }

  Future<void> _onRulesUpdated(
    AiRulesUpdated event,
    Emitter<AiGameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) {
      return;
    }

    emit(
      state.upsertSession(
        session.copyWith(
          rules: event.rules,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onDifficultyUpdated(
    AiDifficultyUpdated event,
    Emitter<AiGameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) {
      return;
    }

    emit(
      state.upsertSession(
        session.copyWith(
          currentDifficulty: event.difficulty,
          difficultyFloor: event.difficulty,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onCitySubmitted(
    AiCitySubmitted event,
    Emitter<AiGameState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || session.status == AiGameStatus.finished) {
      return;
    }

    if (session.isAiThinking) {
      return;
    }

    final userTurn = await _validateUserTurn(session, event.cityName);
    final sessionWithUserTurn = session.withTurn(userTurn);
    emit(
      state.upsertSession(
        sessionWithUserTurn.copyWith(
          isAiThinking: false,
          updatedAt: DateTime.now(),
        ),
      ),
    );

    if (userTurn.status != AiTurnStatus.accepted) {
      return;
    }

    final thinkingSession = sessionWithUserTurn.copyWith(isAiThinking: true);
    emit(state.upsertSession(thinkingSession));

    final aiResult = await _aiMoveService.chooseMove(thinkingSession);
    final nextFatigue = thinkingSession.fatigue.advance(
      thinkingSession.currentDifficulty.fatigueGrowthPerMove,
    );

    if (aiResult.surrendered) {
      const surrenderTurn = AiTurn(
        actor: AiTurnActor.ai,
        input: '',
        status: AiTurnStatus.surrendered,
      );
      emit(
        state.upsertSession(
          thinkingSession
              .withTurn(surrenderTurn)
              .copyWith(
                fatigue: nextFatigue,
                status: AiGameStatus.finished,
                winner: AiGameWinner.user,
                isAiThinking: false,
                updatedAt: DateTime.now(),
              ),
        ),
      );
      return;
    }

    final aiTurn = aiResult.turn!;
    emit(
      state.upsertSession(
        thinkingSession
            .withTurn(aiTurn)
            .copyWith(
              fatigue: nextFatigue,
              isAiThinking: false,
              updatedAt: DateTime.now(),
            ),
      ),
    );
  }

  Future<AiTurn> _validateUserTurn(
    AiGameSession session,
    String rawInput,
  ) async {
    final input = rawInput.trim();
    if (input.isEmpty) {
      return AiTurn(
        actor: AiTurnActor.user,
        input: rawInput,
        status: AiTurnStatus.rejected,
        rejectReason: AiTurnRejectReason.emptyInput,
        expectedStartLetter: session.expectedStartLetter,
      );
    }

    final expectedStartLetter = session.expectedStartLetter;
    if (expectedStartLetter.isNotEmpty) {
      final firstInputLetter = firstLetter(input);
      if (firstInputLetter == null ||
          !areLettersCompatible(firstInputLetter, expectedStartLetter)) {
        return AiTurn(
          actor: AiTurnActor.user,
          input: input,
          status: AiTurnStatus.rejected,
          rejectReason: AiTurnRejectReason.wrongStartLetter,
          expectedStartLetter: expectedStartLetter,
        );
      }
    }

    final locality = await _citiesRepository.findLocalityByName(input);
    if (locality == null) {
      return AiTurn(
        actor: AiTurnActor.user,
        input: input,
        status: AiTurnStatus.rejected,
        rejectReason: AiTurnRejectReason.notFound,
        expectedStartLetter: expectedStartLetter,
      );
    }

    final duplicateAccepted = session.turns.any(
      (turn) =>
          turn.status == AiTurnStatus.accepted &&
          turn.locality?.id == locality.id,
    );

    if (duplicateAccepted) {
      String? duplicateMatchedName;
      for (final turn in session.turns.reversed) {
        if (turn.status == AiTurnStatus.accepted &&
            turn.locality?.id == locality.id) {
          duplicateMatchedName = turn.locality?.matchedName;
          break;
        }
      }

      return AiTurn(
        actor: AiTurnActor.user,
        input: input,
        status: AiTurnStatus.rejected,
        locality: locality,
        rejectReason: AiTurnRejectReason.alreadyUsed,
        expectedStartLetter: expectedStartLetter,
        duplicateMatchedName: duplicateMatchedName,
      );
    }

    if (!session.rules.isAllowedType(locality.cityType)) {
      return AiTurn(
        actor: AiTurnActor.user,
        input: input,
        status: AiTurnStatus.rejected,
        locality: locality,
        rejectReason: AiTurnRejectReason.typeNotAllowed,
        expectedStartLetter: expectedStartLetter,
      );
    }

    if (!session.rules.allowHistoricalNames &&
        locality.matchedLang == 'old_name') {
      return AiTurn(
        actor: AiTurnActor.user,
        input: input,
        status: AiTurnStatus.rejected,
        locality: locality,
        rejectReason: AiTurnRejectReason.oldNameNotAllowed,
        expectedStartLetter: expectedStartLetter,
      );
    }

    final population = locality.population ?? 0;
    if (population < session.rules.minPopulation) {
      return AiTurn(
        actor: AiTurnActor.user,
        input: input,
        status: AiTurnStatus.rejected,
        locality: locality,
        rejectReason: AiTurnRejectReason.belowMinPopulation,
        expectedStartLetter: expectedStartLetter,
      );
    }

    return AiTurn(
      actor: AiTurnActor.user,
      input: input,
      status: AiTurnStatus.accepted,
      locality: locality,
    );
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'ai_session_${now}_$random';
  }

  @override
  AiGameState? fromJson(Map<String, dynamic> json) {
    return AiGameState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AiGameState state) {
    return state.toJson();
  }
}

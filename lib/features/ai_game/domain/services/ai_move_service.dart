import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../mediator/domain/models/locality.dart';
import '../../../mediator/domain/repos/cities_repository.dart';
import '../models/ai_game_session.dart';
import '../models/ai_turn.dart';

class AiMoveResult {
  final AiTurn? turn;
  final Duration delay;

  const AiMoveResult({
    required this.turn,
    required this.delay,
  });

  bool get surrendered => turn == null;
}

@singleton
class AiMoveService {
  final CitiesRepository _citiesRepository;
  final Random _random = Random();

  AiMoveService({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository;

  Future<AiMoveResult> chooseMove(AiGameSession session) async {
    final startLetter = session.expectedStartLetter;
    final config = session.currentDifficulty;

    final delay = _thinkingDelay(session);
    if (delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }

    if (startLetter.isEmpty) {
      return AiMoveResult(turn: null, delay: delay);
    }

    final candidates = await _citiesRepository.findCandidatesByStartLetter(
      startLetter: startLetter,
      allowedTypes: session.rules.allowedTypes,
      allowHistoricalNames: session.rules.allowHistoricalNames,
      minPopulation: session.rules.minPopulation,
      usedPlaceIds: session.turns
          .where(
            (turn) =>
                turn.status == AiTurnStatus.accepted && turn.locality != null,
          )
          .map((turn) => turn.locality!.id)
          .toSet(),
      preferredLang: session.preferredUserLang,
      limit: max(40, config.candidatePoolSize * 10),
    );

    if (candidates.isEmpty) {
      return AiMoveResult(turn: null, delay: delay);
    }

    final surrenderChance = min(
      0.9,
      config.surrenderChance + (session.fatigue.fatigue * 0.01),
    );
    if (_random.nextDouble() < surrenderChance) {
      return AiMoveResult(turn: null, delay: delay);
    }

    final mistakeChance = min(
      0.95,
      config.mistakeChance +
          (session.fatigue.fatigue * config.fatigueMistakePerPoint),
    );
    final topPoolSize = min(config.candidatePoolSize, candidates.length);
    final topPool = candidates.take(topPoolSize).toList(growable: false);

    final selected = _random.nextDouble() < mistakeChance
        ? _pickFromMistakePool(candidates, topPoolSize)
        : _pickRandom(topPool);

    if (selected == null) {
      return AiMoveResult(turn: null, delay: delay);
    }

    return AiMoveResult(
      delay: delay,
      turn: AiTurn(
        actor: AiTurnActor.ai,
        input: selected.matchedName,
        status: AiTurnStatus.accepted,
        locality: selected,
      ),
    );
  }

  Future<Locality?> pickHint(AiGameSession session) async {
    final startLetter = session.expectedStartLetter;
    if (startLetter.isEmpty) {
      return null;
    }

    final candidates = await _citiesRepository.findCandidatesByStartLetter(
      startLetter: startLetter,
      allowedTypes: session.rules.allowedTypes,
      allowHistoricalNames: session.rules.allowHistoricalNames,
      minPopulation: session.rules.minPopulation,
      usedPlaceIds: session.turns
          .where(
            (turn) =>
                turn.status == AiTurnStatus.accepted && turn.locality != null,
          )
          .map((turn) => turn.locality!.id)
          .toSet(),
      preferredLang: session.preferredUserLang,
      limit: 40,
    );

    return candidates.isEmpty ? null : candidates.first;
  }

  Duration _thinkingDelay(AiGameSession session) {
    final config = session.currentDifficulty;
    final fatigueMs = (session.fatigue.fatigue * config.fatigueDelayPerPointMs)
        .round();
    final jitter = _random.nextInt(250);
    return Duration(
      milliseconds: config.baseThinkingDelayMs + fatigueMs + jitter,
    );
  }

  Locality? _pickRandom(List<Locality> pool) {
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  Locality? _pickFromMistakePool(List<Locality> candidates, int topPoolSize) {
    if (candidates.isEmpty) {
      return null;
    }

    final startIndex = min(topPoolSize, candidates.length);
    final mistakePool = candidates.length > startIndex
        ? candidates.sublist(startIndex)
        : candidates;

    return _pickRandom(mistakePool.isNotEmpty ? mistakePool : candidates);
  }
}

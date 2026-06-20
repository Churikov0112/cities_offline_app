import 'package:injectable/injectable.dart';

import '../../../mediator/domain/repos/cities_repository.dart';
import '../../../mediator/domain/utils/city_name_utils.dart';
import '../models/game_session.dart';
import '../models/game_turn.dart';

@singleton
class TurnValidator {
  final CitiesRepository _citiesRepository;

  TurnValidator({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository;

  Future<GameTurn> validate(
    GameSession session,
    String rawInput, {
    GameTurnActor actor = GameTurnActor.user,
  }) async {
    final input = rawInput.trim();

    if (input.isEmpty) {
      return GameTurn(
        actor: actor,
        input: rawInput,
        status: GameTurnStatus.rejected,
        rejectReason: GameTurnRejectReason.emptyInput,
        expectedStartLetter: session.expectedStartLetter,
      );
    }

    final expectedStartLetter = session.expectedStartLetter;
    if (expectedStartLetter.isNotEmpty) {
      final firstInputLetter = firstLetter(input);
      if (firstInputLetter == null ||
          !areLettersCompatible(firstInputLetter, expectedStartLetter)) {
        return GameTurn(
          actor: actor,
          input: input,
          status: GameTurnStatus.rejected,
          rejectReason: GameTurnRejectReason.wrongStartLetter,
          expectedStartLetter: expectedStartLetter,
        );
      }
    }

    final locality = await _citiesRepository.findLocalityByName(
      input,
      preferredLang: session.preferredUserLang,
    );
    if (locality == null) {
      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        rejectReason: GameTurnRejectReason.notFound,
        expectedStartLetter: expectedStartLetter,
      );
    }

    final duplicateAccepted = session.turns.any(
      (turn) =>
          turn.status == GameTurnStatus.accepted &&
          turn.locality?.id == locality.id,
    );
    if (duplicateAccepted) {
      String? duplicateMatchedName;
      for (final turn in session.turns.reversed) {
        if (turn.status == GameTurnStatus.accepted &&
            turn.locality?.id == locality.id) {
          duplicateMatchedName = turn.locality?.matchedName;
          break;
        }
      }

      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        locality: locality,
        rejectReason: GameTurnRejectReason.alreadyUsed,
        expectedStartLetter: expectedStartLetter,
        duplicateMatchedName: duplicateMatchedName,
      );
    }

    if (!session.rules.isAllowedTypeFromString(locality.cityType)) {
      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        locality: locality,
        rejectReason: GameTurnRejectReason.typeNotAllowed,
        expectedStartLetter: expectedStartLetter,
      );
    }

    if (!session.rules.isAllowedCountry(locality.countryCode)) {
      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        locality: locality,
        rejectReason: GameTurnRejectReason.countryNotAllowed,
        expectedStartLetter: expectedStartLetter,
      );
    }

    if (!session.rules.allowHistoricalNames &&
        locality.matchedLang == 'old_name') {
      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        locality: locality,
        rejectReason: GameTurnRejectReason.oldNameNotAllowed,
        expectedStartLetter: expectedStartLetter,
      );
    }

    final population = locality.population ?? 0;
    if (population < session.rules.minPopulation) {
      return GameTurn(
        actor: actor,
        input: input,
        status: GameTurnStatus.rejected,
        locality: locality,
        rejectReason: GameTurnRejectReason.belowMinPopulation,
        expectedStartLetter: expectedStartLetter,
      );
    }

    return GameTurn(
      actor: actor,
      input: input,
      status: GameTurnStatus.accepted,
      locality: locality,
    );
  }
}

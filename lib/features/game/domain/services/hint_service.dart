import 'package:injectable/injectable.dart';

import '../../../mediator/domain/models/locality.dart';
import '../../../mediator/domain/repos/cities_repository.dart';
import '../models/game_session.dart';

@singleton
class HintService {
  final CitiesRepository _citiesRepository;

  HintService({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository;

  Future<Locality?> pickHint(GameSession session) async {
    final startLetter = session.expectedStartLetter;
    if (startLetter.isEmpty) {
      return null;
    }

    final usedIds = session.acceptedLocalityIds;

    final candidates = await _citiesRepository.findCandidatesByStartLetter(
      startLetter: startLetter,
      allowedTypes: session.rules.allowedTypeStrings,
      allowHistoricalNames: session.rules.allowHistoricalNames,
      minPopulation: session.rules.minPopulation,
      allowedCountryCodes: session.rules.allowedCountryCodes,
      usedPlaceIds: usedIds,
      preferredLang: session.preferredUserLang,
      limit: 1,
    );

    return candidates.isEmpty ? null : candidates.first;
  }
}

part of 'mediator_bloc.dart';

sealed class MediatorEvent {
  const MediatorEvent();
}

class MediatorSessionCreated extends MediatorEvent {
  final MediatorGameRules rules;

  const MediatorSessionCreated(this.rules);
}

class MediatorCitySubmitted extends MediatorEvent {
  final String sessionId;
  final String cityName;

  const MediatorCitySubmitted({
    required this.sessionId,
    required this.cityName,
  });
}

class MediatorRulesUpdated extends MediatorEvent {
  final String sessionId;
  final MediatorGameRules rules;

  const MediatorRulesUpdated({required this.sessionId, required this.rules});
}

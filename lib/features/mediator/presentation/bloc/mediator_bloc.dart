import 'dart:math';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/models/mediator_game_rules.dart';
import '../../domain/models/mediator_session.dart';
import '../../domain/models/mediator_turn.dart';
import '../../domain/repos/cities_repository.dart';
import '../../domain/utils/utils.dart';

part 'mediator_event.dart';
part 'mediator_state.dart';

@singleton
class MediatorBloc extends HydratedBloc<MediatorEvent, MediatorState> {
  final CitiesRepository _citiesRepository;

  MediatorBloc({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository,
      super(const MediatorState.initial()) {
    on<MediatorSessionCreated>(_onSessionCreated);
    on<MediatorCitySubmitted>(_onCitySubmitted);
    on<MediatorRulesUpdated>(_onRulesUpdated);
  }

  Future<void> _onSessionCreated(
    MediatorSessionCreated event,
    Emitter<MediatorState> emit,
  ) async {
    final now = DateTime.now();
    final session = MediatorSession(
      id: _generateId(),
      createdAt: now,
      updatedAt: now,
      rules: event.rules,
      turns: const [],
    );
    emit(state.upsertSession(session));
  }

  Future<void> _onRulesUpdated(
    MediatorRulesUpdated event,
    Emitter<MediatorState> emit,
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

  Future<void> _onCitySubmitted(
    MediatorCitySubmitted event,
    Emitter<MediatorState> emit,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null) {
      return;
    }

    final input = event.cityName.trim();

    if (input.isEmpty) {
      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: event.cityName,
              status: MediatorTurnStatus.rejected,
              rejectReason: MediatorTurnRejectReason.emptyInput,
              expectedStartLetter: session.expectedStartLetter,
            ),
          ),
        ),
      );
      return;
    }

    final locality = await _citiesRepository.findLocalityByName(input);
    final expectedStartLetter = session.expectedStartLetter;

    if (expectedStartLetter != null) {
      final firstInputLetter = firstLetter(input);
      if (firstInputLetter == null ||
          !areLettersCompatible(firstInputLetter, expectedStartLetter)) {
        emit(
          state.upsertSession(
            session.withTurn(
              MediatorTurn(
                input: input,
                status: MediatorTurnStatus.rejected,
                rejectReason: MediatorTurnRejectReason.wrongStartLetter,
                expectedStartLetter: expectedStartLetter,
              ),
            ),
          ),
        );
        return;
      }
    }

    if (locality == null) {
      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: input,
              status: MediatorTurnStatus.rejected,
              rejectReason: MediatorTurnRejectReason.notFound,
              expectedStartLetter: expectedStartLetter,
            ),
          ),
        ),
      );
      return;
    }

    final duplicateAccepted = session.turns.any(
      (turn) =>
          turn.status == MediatorTurnStatus.accepted &&
          turn.locality?.id == locality.id,
    );

    if (duplicateAccepted) {
      String? duplicateMatchedName;
      for (final turn in session.turns.reversed) {
        if (turn.status == MediatorTurnStatus.accepted &&
            turn.locality?.id == locality.id) {
          duplicateMatchedName = turn.locality?.matchedName;
          break;
        }
      }

      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: input,
              status: MediatorTurnStatus.rejected,
              locality: locality,
              rejectReason: MediatorTurnRejectReason.alreadyUsed,
              expectedStartLetter: expectedStartLetter,
              duplicateMatchedName: duplicateMatchedName,
            ),
          ),
        ),
      );
      return;
    }

    if (!session.rules.isAllowedType(locality.cityType)) {
      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: input,
              status: MediatorTurnStatus.rejected,
              locality: locality,
              rejectReason: MediatorTurnRejectReason.typeNotAllowed,
              expectedStartLetter: expectedStartLetter,
            ),
          ),
        ),
      );
      return;
    }

    if (!session.rules.allowHistoricalNames &&
        locality.matchedLang == 'old_name') {
      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: input,
              status: MediatorTurnStatus.rejected,
              locality: locality,
              rejectReason: MediatorTurnRejectReason.oldNameNotAllowed,
              expectedStartLetter: expectedStartLetter,
            ),
          ),
        ),
      );
      return;
    }

    final population = locality.population ?? 0;
    if (population < session.rules.minPopulation) {
      emit(
        state.upsertSession(
          session.withTurn(
            MediatorTurn(
              input: input,
              status: MediatorTurnStatus.rejected,
              locality: locality,
              rejectReason: MediatorTurnRejectReason.belowMinPopulation,
              expectedStartLetter: expectedStartLetter,
            ),
          ),
        ),
      );
      return;
    }

    emit(
      state.upsertSession(
        session.withTurn(
          MediatorTurn(
            input: input,
            status: MediatorTurnStatus.accepted,
            locality: locality,
          ),
        ),
      ),
    );
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'session_${now}_$random';
  }

  @override
  MediatorState? fromJson(Map<String, dynamic> json) {
    return MediatorState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(MediatorState state) {
    return state.toJson();
  }
}

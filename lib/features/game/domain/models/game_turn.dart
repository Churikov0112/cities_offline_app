import '../../../mediator/domain/models/locality.dart';

enum GameTurnActor { user, ai }

enum GameTurnStatus { accepted, rejected, surrendered }

enum GameTurnRejectReason {
  emptyInput,
  notFound,
  alreadyUsed,
  wrongStartLetter,
  typeNotAllowed,
  oldNameNotAllowed,
  belowMinPopulation,
  countryNotAllowed,
}

class GameTurn {
  final GameTurnActor actor;
  final String input;
  final GameTurnStatus status;
  final Locality? locality;
  final GameTurnRejectReason? rejectReason;
  final String? expectedStartLetter;
  final String? duplicateMatchedName;

  const GameTurn({
    required this.actor,
    required this.input,
    required this.status,
    this.locality,
    this.rejectReason,
    this.expectedStartLetter,
    this.duplicateMatchedName,
  });

  Map<String, dynamic> toJson() {
    return {
      'actor': actor.name,
      'input': input,
      'status': status.name,
      'locality': locality?.toJson(),
      'rejectReason': rejectReason?.name,
      'expectedStartLetter': expectedStartLetter,
      'duplicateMatchedName': duplicateMatchedName,
    };
  }

  factory GameTurn.fromJson(Map<String, dynamic> json) {
    return GameTurn(
      actor: GameTurnActor.values.firstWhere(
        (e) => e.name == json['actor'],
        orElse: () => GameTurnActor.user,
      ),
      input: json['input'] as String,
      status: GameTurnStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameTurnStatus.rejected,
      ),
      locality: json['locality'] == null
          ? null
          : Locality.fromJson(
              (json['locality'] as Map).cast<String, dynamic>(),
            ),
      rejectReason: _reasonFromString(json['rejectReason'] as String?),
      expectedStartLetter: json['expectedStartLetter'] as String?,
      duplicateMatchedName: json['duplicateMatchedName'] as String?,
    );
  }

  static GameTurnRejectReason? _reasonFromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final reason in GameTurnRejectReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return null;
  }
}

import '../../../mediator/domain/models/locality.dart';

enum AiTurnActor { user, ai }

enum AiTurnStatus { accepted, rejected, surrendered }

enum AiTurnRejectReason {
  emptyInput,
  notFound,
  alreadyUsed,
  wrongStartLetter,
  typeNotAllowed,
  oldNameNotAllowed,
  belowMinPopulation,
}

class AiTurn {
  final AiTurnActor actor;
  final String input;
  final AiTurnStatus status;
  final Locality? locality;
  final AiTurnRejectReason? rejectReason;
  final String? expectedStartLetter;
  final String? duplicateMatchedName;

  const AiTurn({
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

  factory AiTurn.fromJson(Map<String, dynamic> json) {
    return AiTurn(
      actor: AiTurnActor.values.firstWhere(
        (e) => e.name == json['actor'],
        orElse: () => AiTurnActor.user,
      ),
      input: json['input'] as String,
      status: AiTurnStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AiTurnStatus.rejected,
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

  static AiTurnRejectReason? _reasonFromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final reason in AiTurnRejectReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return null;
  }
}

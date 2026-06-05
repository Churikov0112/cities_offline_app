import 'locality.dart';

enum MediatorTurnStatus { accepted, rejected }

enum MediatorTurnRejectReason {
  emptyInput,
  notFound,
  alreadyUsed,
  wrongStartLetter,
  typeNotAllowed,
  oldNameNotAllowed,
  belowMinPopulation,
  countryNotAllowed,
}

class MediatorTurn {
  final String input;
  final MediatorTurnStatus status;
  final Locality? locality;
  final MediatorTurnRejectReason? rejectReason;
  final String? expectedStartLetter;
  final String? duplicateMatchedName;

  const MediatorTurn({
    required this.input,
    required this.status,
    this.locality,
    this.rejectReason,
    this.expectedStartLetter,
    this.duplicateMatchedName,
  });

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'status': status.name,
      'locality': locality?.toJson(),
      'rejectReason': rejectReason?.name,
      'expectedStartLetter': expectedStartLetter,
      'duplicateMatchedName': duplicateMatchedName,
    };
  }

  factory MediatorTurn.fromJson(Map<String, dynamic> json) {
    return MediatorTurn(
      input: json['input'] as String,
      status: MediatorTurnStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MediatorTurnStatus.rejected,
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

  static MediatorTurnRejectReason? _reasonFromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final reason in MediatorTurnRejectReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return null;
  }
}

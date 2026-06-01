part of 'mediator_bloc.dart';

class MediatorState {
  final Map<String, MediatorSession> sessions;
  final List<String> orderedSessionIds;

  const MediatorState({
    required this.sessions,
    required this.orderedSessionIds,
  });

  const MediatorState.initial()
    : sessions = const {},
      orderedSessionIds = const [];

  List<MediatorSession> get orderedSessions {
    return orderedSessionIds
        .map((id) => sessions[id])
        .whereType<MediatorSession>()
        .toList(growable: false);
  }

  MediatorSession? sessionById(String id) => sessions[id];

  MediatorState upsertSession(MediatorSession session) {
    final hasSession = sessions.containsKey(session.id);
    return MediatorState(
      sessions: {
        ...sessions,
        session.id: session,
      },
      orderedSessionIds: hasSession
          ? orderedSessionIds
          : [session.id, ...orderedSessionIds],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((key, value) => MapEntry(key, value.toJson())),
      'orderedSessionIds': orderedSessionIds,
    };
  }

  factory MediatorState.fromJson(Map<String, dynamic> json) {
    final rawSessions =
        (json['sessions'] as Map?)?.cast<String, dynamic>() ?? {};

    final sessions = rawSessions.map(
      (key, value) => MapEntry(
        key,
        MediatorSession.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );

    final orderedSessionIds =
        ((json['orderedSessionIds'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList();

    return MediatorState(
      sessions: sessions,
      orderedSessionIds: orderedSessionIds,
    );
  }
}

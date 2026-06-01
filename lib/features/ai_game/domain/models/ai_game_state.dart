import 'ai_game_session.dart';

class AiGameState {
  final Map<String, AiGameSession> sessions;
  final List<String> orderedSessionIds;

  const AiGameState({
    required this.sessions,
    required this.orderedSessionIds,
  });

  const AiGameState.initial()
    : sessions = const {},
      orderedSessionIds = const [];

  List<AiGameSession> get orderedSessions {
    return orderedSessionIds
        .map((id) => sessions[id])
        .whereType<AiGameSession>()
        .toList(growable: false);
  }

  AiGameSession? sessionById(String id) => sessions[id];

  AiGameState upsertSession(AiGameSession session) {
    final hasSession = sessions.containsKey(session.id);
    return AiGameState(
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

  factory AiGameState.fromJson(Map<String, dynamic> json) {
    final rawSessions =
        (json['sessions'] as Map?)?.cast<String, dynamic>() ?? {};
    final sessions = rawSessions.map(
      (key, value) => MapEntry(
        key,
        AiGameSession.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );

    final orderedSessionIds =
        ((json['orderedSessionIds'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList();

    return AiGameState(
      sessions: sessions,
      orderedSessionIds: orderedSessionIds,
    );
  }
}

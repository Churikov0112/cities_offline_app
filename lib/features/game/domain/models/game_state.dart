import 'game_session.dart';

class GameState {
  final Map<String, GameSession> sessions;
  final List<String> orderedSessionIds;

  const GameState({
    required this.sessions,
    required this.orderedSessionIds,
  });

  const GameState.initial()
    : sessions = const {},
      orderedSessionIds = const [];

  List<GameSession> get orderedSessions {
    return orderedSessionIds
        .map((id) => sessions[id])
        .whereType<GameSession>()
        .toList(growable: false);
  }

  GameSession? sessionById(String id) => sessions[id];

  GameState upsertSession(GameSession session) {
    final hasSession = sessions.containsKey(session.id);
    return GameState(
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

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawSessions =
        (json['sessions'] as Map?)?.cast<String, dynamic>() ?? {};
    final sessions = rawSessions.map(
      (key, value) => MapEntry(
        key,
        GameSession.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );

    final orderedSessionIds =
        ((json['orderedSessionIds'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList();

    return GameState(
      sessions: sessions,
      orderedSessionIds: orderedSessionIds,
    );
  }
}

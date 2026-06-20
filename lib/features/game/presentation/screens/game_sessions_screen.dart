import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/game_session.dart';
import '../../domain/models/game_state.dart';
import '../bloc/game_bloc.dart';

class GameSessionsScreen extends StatelessWidget {
  const GameSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<GameBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/game/rules'),
                    icon: const Icon(Icons.add),
                    label: Translator(
                      termin: AppGlossary.newGame,
                      builder: (text) => Text(text),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<GameBloc, GameState>(
                  builder: (context, state) {
                    final sessions = state.orderedSessions;
                    if (sessions.isEmpty) {
                      return Center(
                        child: Translator(
                          termin: AppGlossary.noSessionsYet,
                          builder: (text) => Text(text),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return ListTile(
                          title: Text(
                            '${AppGlossary.sessionFrom.translate()} ${session.createdAt.toLocal()}',
                          ),
                          subtitle: Text(
                            '${AppGlossary.movesCount.translate()} ${session.turns.length} · ${session.opponent == OpponentType.ai ? 'AI' : 'PvP'}${session.isVoiceEnabled ? ' · 🎤' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/game/${session.id}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

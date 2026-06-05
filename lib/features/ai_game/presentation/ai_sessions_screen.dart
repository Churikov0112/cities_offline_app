import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_state.dart';
import 'package:cities_offline_app/features/ai_game/presentation/bloc/ai_game_bloc.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AiSessionsScreen extends StatelessWidget {
  const AiSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AiGameBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Translator(
            termin: AppGlossary.userVsAi,
            builder: (text) => Text(text),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.pushNamed(RoutePaths.aiRules.name),
                    icon: const Icon(Icons.add),
                    label: Translator(
                      termin: AppGlossary.newGame,
                      builder: (text) => Text(text),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<AiGameBloc, AiGameState>(
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
                            '${AppGlossary.movesCount.translate()} ${session.turns.length} · ${AppGlossary.difficulty.translate()}: ${translateDifficultyPreset(session.currentDifficulty.preset.name)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.pushNamed(
                              RoutePaths.aiGame.name,
                              pathParameters: {'sessionId': session.id},
                            );
                          },
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

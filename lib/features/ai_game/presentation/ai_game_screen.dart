import 'package:cities_offline_app/core/ui_kit/widgets/ai_turn_card/ai_turn_card.dart';
import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_session.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_state.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_turn.dart';
import 'package:cities_offline_app/features/ai_game/presentation/bloc/ai_game_bloc.dart';
import 'package:cities_offline_app/services/localization/country_names.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'ai_game_screen_presenter.dart';

class AiGameScreen extends StatelessWidget {
  final String sessionId;

  const AiGameScreen({required this.sessionId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AiGameBloc>(),
      child: AiGameScreenPresenter(
        sessionId: sessionId,
        child: Builder(
          builder: (context) {
            final presenter = AiGameScreenPresenter.of(context);

            return Scaffold(
              appBar: AppBar(
                title: Translator(
                  termin: AppGlossary.userVsAi,
                  builder: (text) => Text(text),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.pushNamed(RoutePaths.aiRulesForSession.name, pathParameters: {'sessionId': sessionId});
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              body: SafeArea(
                child: BlocSelector<AiGameBloc, AiGameState, AiGameSession?>(
                  selector: (state) => state.sessionById(sessionId),
                  builder: (context, session) {
                    if (session == null) {
                      return const Center(child: Text('Сессия не найдена'));
                    }

                    final winnerTerm = switch (session.winner) {
                      AiGameWinner.user => AppGlossary.youWon,
                      AiGameWinner.ai => AppGlossary.aiWon,
                      null => AppGlossary.gameFinished,
                    };

                    return Column(
                      children: [
                        if (session.status == AiGameStatus.finished)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: _ResultBanner(term: winnerTerm),
                          ),
                        Expanded(
                          child: session.turns.isEmpty && !session.isAiThinking
                              ? Center(
                                  child: Translator(
                                    termin: AppGlossary.enterCity,
                                    builder: (text) => Text(text),
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: session.turns.length + (session.isAiThinking ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (session.isAiThinking && index == 0) {
                                      return const AiThinkingCard();
                                    }

                                    final adjustedIndex = session.isAiThinking ? index - 1 : index;
                                    final turn = session.turns[session.turns.length - 1 - adjustedIndex];
                                    return AiTurnCard(
                                      key: ValueKey(
                                        '${turn.actor.name}-${turn.input}-$index-${turn.locality?.id ?? "none"}-$sessionId',
                                      ),
                                      turn: turn,
                                      rejectReasonText: presenter.rejectReasonText(turn),
                                    );
                                  },
                                ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: presenter.controller,
                            builder: (context, _, _) {
                              final canSubmit =
                                  presenter.canSubmit && !session.isAiThinking && session.status == AiGameStatus.active;
                              return Row(
                                children: [
                                  IconButton(
                                    onPressed: !session.isAiThinking && session.status == AiGameStatus.active
                                        ? presenter.requestHint
                                        : null,
                                    icon: const Icon(Icons.help_outline),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: presenter.controller,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => presenter.submitCity(),
                                      enabled: !session.isAiThinking && session.status == AiGameStatus.active,
                                      decoration: InputDecoration(
                                        hintText: AppGlossary.enterCity.translate(),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: canSubmit ? presenter.submitCity : null,
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final AppGlossary term;

  const _ResultBanner({required this.term});

  @override
  Widget build(BuildContext context) {
    return Translator(
      termin: term,
      builder: (text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


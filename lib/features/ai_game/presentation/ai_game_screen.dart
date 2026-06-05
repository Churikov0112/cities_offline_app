import 'dart:async';

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_session.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_state.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_turn.dart';
import 'package:cities_offline_app/features/ai_game/presentation/bloc/ai_game_bloc.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../mediator/domain/models/locality.dart';

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
                title: const Text('Пользователь против ПК'),
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

                    final winnerText = switch (session.winner) {
                      AiGameWinner.user => 'Ты победил',
                      AiGameWinner.ai => 'ПК победил',
                      null => 'Партия завершена',
                    };

                    return Column(
                      children: [
                        if (session.status == AiGameStatus.finished)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: _ResultBanner(text: winnerText),
                          ),
                        Expanded(
                          child: session.turns.isEmpty && !session.isAiThinking
                              ? const Center(child: Text('Введите первый населенный пункт'))
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: session.turns.length + (session.isAiThinking ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (session.isAiThinking && index == 0) {
                                      return const _AiThinkingCard();
                                    }

                                    final adjustedIndex = session.isAiThinking ? index - 1 : index;
                                    final turn = session.turns[session.turns.length - 1 - adjustedIndex];
                                    return _AiTurnCard(
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
                                      decoration: const InputDecoration(
                                        hintText: 'Введите населенный пункт',
                                        border: OutlineInputBorder(),
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
  final String text;

  const _ResultBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _AiThinkingCard extends StatefulWidget {
  const _AiThinkingCard();

  @override
  State<_AiThinkingCard> createState() => _AiThinkingCardState();
}

class _AiThinkingCardState extends State<_AiThinkingCard> {
  static const _frames = ['', '.', '..', '...'];
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _index = (_index + 1) % _frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const SizedBox(width: 28, child: Icon(Icons.smart_toy_outlined, size: 18)),
            const SizedBox(width: 8),
            const Text('Думаю', style: TextStyle(fontWeight: FontWeight.w600)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                _frames[_index],
                key: ValueKey(_index),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTurnCard extends StatefulWidget {
  final AiTurn turn;
  final String rejectReasonText;

  const _AiTurnCard({required this.turn, required this.rejectReasonText, super.key});

  @override
  State<_AiTurnCard> createState() => _AiTurnCardState();
}

class _AiTurnCardState extends State<_AiTurnCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.turn.locality != null;
    final isAi = widget.turn.actor == AiTurnActor.ai;

    return Card(
      child: InkWell(
        onTap: canExpand ? _toggleExpanded : null,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: widget.turn.input));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAi ? 'ИИ' : 'Игрок',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAi ? Colors.deepPurple : Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _AiTurnName(turn: widget.turn),
                        if (widget.turn.status == AiTurnStatus.rejected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(widget.rejectReasonText, style: const TextStyle(color: Colors.redAccent)),
                          ),
                        if (widget.turn.status == AiTurnStatus.surrendered)
                          const Padding(padding: EdgeInsets.only(top: 4), child: Text('Я сдаюсь, ты победил')),
                      ],
                    ),
                  ),
                  if (canExpand)
                    IconButton(
                      onPressed: _toggleExpanded,
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded && canExpand
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _LocalityDetails(locality: widget.turn.locality!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}

class _AiTurnName extends StatelessWidget {
  final AiTurn turn;

  const _AiTurnName({required this.turn});

  @override
  Widget build(BuildContext context) {
    final text = turn.locality?.matchedName ?? turn.input;
    if (turn.status != AiTurnStatus.accepted || text.isEmpty) {
      return Text(text);
    }

    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }
}

class _LocalityDetails extends StatelessWidget {
  final Locality locality;

  const _LocalityDetails({required this.locality});

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[
      if (locality.population != null)
        _detailRow('Население', locality.population.toString()),
      _detailRow('Тип', locality.cityType),
      if (locality.lat != null && locality.lon != null)
        _detailRow('Координаты', '${locality.lat!.toStringAsFixed(4)}, ${locality.lon!.toStringAsFixed(4)}'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...details,
          if (locality.lat != null && locality.lon != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.pushNamed(
                    RoutePaths.map.name,
                    queryParameters: {
                      'lat': locality.lat.toString(),
                      'lon': locality.lon.toString(),
                      'name': locality.matchedName,
                    },
                  );
                },
                icon: const Icon(Icons.map, size: 16),
                label: const Text('На карте', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}

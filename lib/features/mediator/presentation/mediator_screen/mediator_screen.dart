import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/mediator/domain/models/locality.dart';
import 'package:cities_offline_app/features/mediator/domain/models/mediator_session.dart';
import 'package:cities_offline_app/features/mediator/domain/models/mediator_turn.dart';
import 'package:cities_offline_app/features/mediator/presentation/bloc/mediator_bloc.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mediator_screen_presenter.dart';

class MediatorScreen extends StatelessWidget {
  final String sessionId;

  const MediatorScreen({required this.sessionId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<MediatorBloc>(),
      child: MediatorScreenPresenter(
        sessionId: sessionId,
        child: Builder(
          builder: (context) {
            final presenter = MediatorScreenPresenter.of(context);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Медиатор'),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.pushNamed(
                        RoutePaths.mediatorRulesForSession.name,
                        pathParameters: {'sessionId': sessionId},
                      );
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              body: SafeArea(
                child: BlocSelector<MediatorBloc, MediatorState, MediatorSession?>(
                  selector: (state) => state.sessionById(sessionId),
                  builder: (context, session) {
                    if (session == null) {
                      return const Center(child: Text('Сессия не найдена'));
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: session.turns.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Введите первый населенный пункт',
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  itemCount: session.turns.length,
                                  itemBuilder: (context, index) {
                                    final turn =
                                        session.turns[session.turns.length -
                                            1 -
                                            index];
                                    return _TurnCard(
                                      key: ValueKey(
                                        '${turn.input}-$index-${turn.locality?.id ?? "none"}-$sessionId',
                                      ),
                                      turn: turn,
                                      rejectReasonText: presenter
                                          .rejectReasonText(turn),
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
                              return Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: presenter.controller,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) =>
                                          presenter.submitCity(),
                                      decoration: const InputDecoration(
                                        hintText: 'Введите населенный пункт',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: presenter.canSubmit
                                        ? presenter.submitCity
                                        : null,
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

class _TurnStatusLabel extends StatelessWidget {
  final MediatorTurn turn;

  const _TurnStatusLabel({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isAccepted = turn.status == MediatorTurnStatus.accepted;
    return Text(
      isAccepted ? 'Принято' : 'Отклонено',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: isAccepted ? Colors.green : Colors.redAccent,
      ),
    );
  }
}

class _TurnCard extends StatefulWidget {
  final MediatorTurn turn;
  final String rejectReasonText;

  const _TurnCard({
    required this.turn,
    required this.rejectReasonText,
    super.key,
  });

  @override
  State<_TurnCard> createState() => _TurnCardState();
}

class _TurnCardState extends State<_TurnCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.turn.locality != null;

    return Card(
      child: InkWell(
        onTap: canExpand ? _toggleExpanded : null,
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
                        _TurnStatusLabel(turn: widget.turn),
                        const SizedBox(height: 6),
                        _TurnName(turn: widget.turn),
                        if (widget.turn.status == MediatorTurnStatus.rejected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.rejectReasonText,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
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
                        child: _LocalityDetails(
                          locality: widget.turn.locality!,
                        ),
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

class _TurnName extends StatelessWidget {
  final MediatorTurn turn;

  const _TurnName({required this.turn});

  @override
  Widget build(BuildContext context) {
    final text = turn.locality?.matchedName ?? turn.input;

    if (turn.status != MediatorTurnStatus.accepted || text.isEmpty) {
      return Text(text);
    }

    final chars = text.characters.toList();
    final lastSignificantIndex = _findLastSignificantIndex(chars);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
        children: List.generate(chars.length, (index) {
          final isFirst = index == 0;
          final isLastSignificant = index == lastSignificantIndex;

          if (isFirst) {
            return TextSpan(
              text: chars[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            );
          }

          if (isLastSignificant) {
            return TextSpan(
              text: chars[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            );
          }

          return TextSpan(text: chars[index]);
        }),
      ),
    );
  }

  int _findLastSignificantIndex(List<String> chars) {
    for (var i = chars.length - 1; i >= 0; i--) {
      if (_ignoredTrailingLetters.contains(chars[i].toLowerCase())) {
        continue;
      }
      return i;
    }
    return chars.length - 1;
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
        _detailRow(
          'Координаты',
          '${locality.lat!.toStringAsFixed(4)}, ${locality.lon!.toStringAsFixed(4)}',
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
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

const Set<String> _ignoredTrailingLetters = {'ь', 'ъ', 'ы', '-', ' ', "'"};

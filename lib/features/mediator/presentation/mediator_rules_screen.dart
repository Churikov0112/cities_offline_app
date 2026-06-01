import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/mediator/domain/models/mediator_game_rules.dart';
import 'package:cities_offline_app/features/mediator/presentation/bloc/mediator_bloc.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MediatorRulesScreen extends StatefulWidget {
  final String? sessionId;

  const MediatorRulesScreen({super.key, this.sessionId});

  @override
  State<MediatorRulesScreen> createState() => _MediatorRulesScreenState();
}

class _MediatorRulesScreenState extends State<MediatorRulesScreen> {
  late MediatorGameRules _rules;
  final _populationController = TextEditingController();
  bool _waitingForNewSession = false;
  Set<String> _knownIds = <String>{};

  // 1. Добавляем поле для блока
  late final MediatorBloc _mediatorBloc;

  @override
  void initState() {
    super.initState();
    // 2. Инициализируем один раз через getIt
    _mediatorBloc = getIt<MediatorBloc>();

    _knownIds = _mediatorBloc.state.sessions.keys.toSet();
    final existing = widget.sessionId == null ? null : _mediatorBloc.state.sessionById(widget.sessionId!);
    _rules = existing?.rules ?? const MediatorGameRules.onlyCities();
    _populationController.text = _rules.minPopulation.toString();
  }

  @override
  void dispose() {
    _populationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _mediatorBloc, // 3. Передаём сохранённый блок
      child: BlocListener<MediatorBloc, MediatorState>(
        listenWhen: (_, current) => _waitingForNewSession,
        listener: (context, state) {
          final newIds = state.sessions.keys.toSet().difference(_knownIds);
          if (newIds.isNotEmpty) {
            final createdId = state.orderedSessionIds.firstWhere(
              (id) => newIds.contains(id),
              orElse: () => newIds.first,
            );
            _waitingForNewSession = false;
            context.goNamed(
              RoutePaths.mediatorGame.name,
              pathParameters: {'sessionId': createdId},
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Настройки игры')),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text('Типы поселений'),
              ...['city', 'town', 'village', 'hamlet'].map(
                (type) => CheckboxListTile(
                  value: _rules.allowedTypes.contains(type),
                  title: Text(type),
                  onChanged: (v) {
                    setState(() {
                      final next = {..._rules.allowedTypes};
                      if (v == true) {
                        next.add(type);
                      } else {
                        next.remove(type);
                      }
                      _rules = _rules.copyWith(allowedTypes: next);
                    });
                  },
                ),
              ),
              SwitchListTile(
                value: _rules.allowHistoricalNames,
                title: const Text('Засчитывать старые названия'),
                onChanged: (v) {
                  setState(() {
                    _rules = _rules.copyWith(allowHistoricalNames: v);
                  });
                },
              ),
              TextField(
                controller: _populationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Минимальная численность населения',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final minPopulation = int.tryParse(_populationController.text) ?? 0;
                  final finalRules = _rules.copyWith(minPopulation: minPopulation);

                  // 4. Используем сохранённый блок — контекст больше не нужен
                  if (widget.sessionId == null) {
                    _knownIds = _mediatorBloc.state.sessions.keys.toSet();
                    _waitingForNewSession = true;
                    _mediatorBloc.add(MediatorSessionCreated(finalRules));
                  } else {
                    _mediatorBloc.add(
                      MediatorRulesUpdated(
                        sessionId: widget.sessionId!,
                        rules: finalRules,
                      ),
                    );
                    context.pop(); // этот context уже внутри поддерева, он работает
                  }
                },
                child: Text(
                  widget.sessionId == null ? 'Создать игру' : 'Сохранить',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/presentation/country_picker_sheet.dart';
import 'package:cities_offline_app/features/mediator/domain/models/mediator_game_rules.dart';
import 'package:cities_offline_app/features/mediator/presentation/bloc/mediator_bloc.dart';
import 'package:cities_offline_app/features/villages/presentation/bloc/villages_cubit.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/bottom_sheet_controller.dart';
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

  late final MediatorBloc _mediatorBloc;

  @override
  void initState() {
    super.initState();
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

  void _showCountryPicker(BuildContext context) {
    BottomSheetController.showBottomSheet(
      context,
      (_) => CountryPickerSheet(
        selectedCodes: _rules.allowedCountryCodes,
        onChanged: (codes) {
          setState(() {
            _rules = _rules.copyWith(allowedCountryCodes: codes);
          });
        },
      ),
      expand: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _mediatorBloc,
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
            context.pushReplacementNamed(
              RoutePaths.mediatorGame.name,
              pathParameters: {'sessionId': createdId},
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Translator(
              termin: AppGlossary.gameSettings,
              builder: (text) => Text(text),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Translator(
                termin: AppGlossary.settlementTypes,
                builder: (text) => Text(text),
              ),
              BlocBuilder<VillagesCubit, VillagesState>(
                builder: (context, villagesState) {
                  return SwitchListTile(
                    value: _rules.allowedTypes.contains('village'),
                    title: Translator(
                      termin: AppGlossary.withVillages,
                      builder: (text) => Text(text),
                    ),
                    subtitle: villagesState.isAvailable
                        ? null
                        : Text(
                            AppGlossary.downloadVillagesDbHint.translate(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                    onChanged: villagesState.isAvailable ? (v) {
                      setState(() {
                        _rules = _rules.copyWith(
                          allowedTypes: v
                              ? {'city', 'town', 'village', 'hamlet'}
                              : {'city', 'town'},
                        );
                      });
                    } : null,
                  );
                },
              ),
                  ListTile(
                    title: Text(AppGlossary.countries.translate()),
                    subtitle: Text(_rules.allowedCountryCodes.isEmpty
                        ? AppGlossary.all.translate()
                        : '${_rules.allowedCountryCodes.length} ${AppGlossary.countries.translate().toLowerCase()}'),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: () => _showCountryPicker(context),
                  ),
                  SwitchListTile(
                    value: _rules.allowHistoricalNames,
                title: Translator(
                  termin: AppGlossary.allowHistoricalNames,
                  builder: (text) => Text(text),
                ),
                onChanged: (v) {
                  setState(() {
                    _rules = _rules.copyWith(allowHistoricalNames: v);
                  });
                },
              ),
              TextField(
                controller: _populationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppGlossary.minPopulation.translate(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final minPopulation = int.tryParse(_populationController.text) ?? 0;
                  final finalRules = _rules.copyWith(minPopulation: minPopulation);

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
                    context.pop();
                  }
                },
                child: Translator(
                  termin: widget.sessionId == null ? AppGlossary.createGame : AppGlossary.save,
                  builder: (text) => Text(text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/mediator/presentation/bloc/mediator_bloc.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MediatorSessionsScreen extends StatelessWidget {
  const MediatorSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<MediatorBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Translator(
            termin: AppGlossary.mediator,
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
                    onPressed: () => context.pushNamed(RoutePaths.mediatorRules.name),
                    icon: const Icon(Icons.add),
                    label: Translator(
                      termin: AppGlossary.newGame,
                      builder: (text) => Text(text),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<MediatorBloc, MediatorState>(
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
                            "${AppGlossary.sessionFrom.translate()} ${DateFormat('d MMM yyyy HH:mm').format(session.createdAt.toLocal())}",
                          ),
                          subtitle: Text(
                            '${AppGlossary.movesCount.translate()} ${session.turns.length}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.pushNamed(
                              RoutePaths.mediatorGame.name,
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

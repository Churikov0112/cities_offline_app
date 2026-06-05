import 'package:flutter/material.dart' show Scaffold, AppBar, ElevatedButton, Icons, IconButton;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/localization/translator.dart';
import '../../../../services/navigation/navigation.dart';

part 'home_screen_presenter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final theme = AppTheme.of(context);

    return HomeScreenPresenter(
      child: Builder(
        builder: (context) {
          // final presenter = HomeScreenPresenter.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Translator(
                termin: AppGlossary.citiesOffline,
                builder: (text) => Text(text),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.pushNamed(RoutePaths.settings.name),
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                // color: theme.colors.system.backgroundPrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        context.pushNamed(RoutePaths.mediator.name);
                      },
                      child: Translator(
                        termin: AppGlossary.mediator,
                        builder: (text) => Text(text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        context.pushNamed(RoutePaths.ai.name);
                      },
                      child: Translator(
                        termin: AppGlossary.userVsAi,
                        builder: (text) => Text(text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart' show Scaffold, AppBar, ElevatedButton;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
            appBar: AppBar(title: const Text('Cities Offline')),
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
                        context.goNamed(RoutePaths.mediator.name);
                      },
                      child: const Text('Mediator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        context.goNamed(RoutePaths.ai.name);
                      },
                      child: const Text('User vs AI'),
                    ),
                  ),
                  // Toggle(
                  //   state: toggleStateSnapshot.data == true ? ToggleState.activeSuccess : ToggleState.$default,
                  //   onChanged: presenter.toggle,
                  // ),
                  // UIBox.base4x,
                  // Button.primary(
                  //   onPressed: () {
                  //     context.goNamed(RoutePaths.sandbox.name);
                  //   },
                  //   elements: [
                  //     ButtonElementText.noFlex(text: 'Sandbox'),
                  //   ],
                  // ),
                  // UIBox.base4x,
                  // Button.primary(
                  //   onPressed: () {
                  //     context.goNamed(RoutePaths.map.name);
                  //   },
                  //   elements: [
                  //     ButtonElementText.noFlex(text: 'Map'),
                  //   ],
                  // ),
                  // UIBox.base4x,
                  // Button.primary(
                  //   onPressed: () {
                  //     context.goNamed(RoutePaths.profile.name);
                  //   },
                  //   elements: [
                  //     ButtonElementText.noFlex(text: 'Profile'),
                  //   ],
                  // ),
                  // UIBox.base4x,
                  // Button.primary(
                  //   onPressed: () {
                  //     FirebaseService.showLocalNotification(
                  //       title: "Local Notification with deeplink",
                  //       body: "https://rsto.dev2.ninedev.ru/map/a/details/info",
                  //       data: {
                  //         "link": "https://rsto.dev2.ninedev.ru/map/a/details/info",
                  //       },
                  //     );
                  //   },
                  //   elements: [
                  //     ButtonElementText.noFlex(text: 'Local Push'),
                  //   ],
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

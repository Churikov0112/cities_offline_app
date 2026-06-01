import 'package:flutter/material.dart';
import 'package:flutter_project_template/src/core/ui_kit/ui_kit.dart';

part '{{name.snakeCase()}}_screen_presenter.dart';

class {{name.pascalCase()}}Screen extends StatelessWidget {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return {{name.pascalCase()}}ScreenPresenter(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.system.backgroundPrimary,
        ),
        child: Column(
          children: [],
        ),
      ),
    );
  }
}


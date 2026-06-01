


import 'package:flutter/widgets.dart';
import 'package:flutter_project_template/src/core/ui_kit/ui_kit.dart';

class {{name.pascalCase()}}BottomSheetHeader extends StatelessWidget {
  const {{name.pascalCase()}}BottomSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container();
  }
}

class {{name.pascalCase()}}BottomSheetBody extends StatelessWidget {
  const {{name.pascalCase()}}BottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      children: [],
    );
  }
}

class {{name.pascalCase()}}BSSaveButton extends StatelessWidget {
  const {{name.pascalCase()}}BSSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: UISize.base4x,
      right: UISize.base4x,
      bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).safeBottomPadding() + UISize.base3x,
      child: PrimaryButton(
        onPressed: () {
        },
        text: 'Сохранить',
      ),
    );
  }
}

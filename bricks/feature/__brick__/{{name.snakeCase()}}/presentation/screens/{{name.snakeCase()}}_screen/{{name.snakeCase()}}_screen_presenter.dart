part of '{{name.snakeCase()}}_screen.dart';

class {{name.pascalCase()}}ScreenPresenter extends StatefulWidget {
  static {{name.pascalCase()}}ScreenPresenterState of(BuildContext context) {
    return context.findAncestorStateOfType<{{name.pascalCase()}}ScreenPresenterState>()!;
  }

  final Widget child;

  const {{name.pascalCase()}}ScreenPresenter({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<{{name.pascalCase()}}ScreenPresenter> createState() => {{name.pascalCase()}}ScreenPresenterState();
}

class {{name.pascalCase()}}ScreenPresenterState extends State<{{name.pascalCase()}}ScreenPresenter> {

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

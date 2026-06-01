part of 'home_screen.dart';

class HomeScreenPresenter extends StatefulWidget {
  static HomeScreenPresenterState of(BuildContext context) {
    return context.findAncestorStateOfType<HomeScreenPresenterState>()!;
  }

  final Widget child;

  const HomeScreenPresenter({
    required this.child,
    super.key,
  });

  @override
  State<HomeScreenPresenter> createState() => HomeScreenPresenterState();
}

class HomeScreenPresenterState extends State<HomeScreenPresenter> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

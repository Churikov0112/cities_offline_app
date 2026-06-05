part of 'ai_game_screen.dart';

class AiGameScreenPresenter extends StatefulWidget {
  final String sessionId;

  static AiGameScreenPresenterState of(BuildContext context) {
    return context.findAncestorStateOfType<AiGameScreenPresenterState>()!;
  }

  final Widget child;

  const AiGameScreenPresenter({
    required this.sessionId,
    required this.child,
    super.key,
  });

  @override
  State<AiGameScreenPresenter> createState() => AiGameScreenPresenterState();
}

class AiGameScreenPresenterState extends State<AiGameScreenPresenter> {
  final TextEditingController controller = TextEditingController();

  bool get canSubmit => controller.text.trim().characters.length >= 2;

  void submitCity() {
    if (!canSubmit) {
      return;
    }
    final value = controller.text;
    context.read<AiGameBloc>().add(
      AiCitySubmitted(sessionId: widget.sessionId, cityName: value),
    );
    controller.clear();
  }

  void requestHint() {
    context.read<AiGameBloc>().add(
      AiHintRequested(sessionId: widget.sessionId),
    );
  }

  String rejectReasonText(AiTurn turn) {
    switch (turn.rejectReason) {
      case AiTurnRejectReason.emptyInput:
        return 'Введите название населенного пункта';
      case AiTurnRejectReason.notFound:
        return 'Населенный пункт не найден в базе';
      case AiTurnRejectReason.alreadyUsed:
        return 'Этот населенный пункт уже использован';
      case AiTurnRejectReason.wrongStartLetter:
        final expected = turn.expectedStartLetter;
        if (expected == null || expected.isEmpty) {
          return 'Неверная первая буква';
        }
        return 'Нужно начать с буквы "$expected"';
      case AiTurnRejectReason.typeNotAllowed:
        final type = turn.locality?.cityType;
        return 'Тип "$type" не засчитывается по текущим настройкам';
      case AiTurnRejectReason.oldNameNotAllowed:
        return 'Исторические названия отключены в правилах';
      case AiTurnRejectReason.belowMinPopulation:
        return 'Население меньше минимального порога из настроек';
      case null:
        return 'Ход отклонен';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

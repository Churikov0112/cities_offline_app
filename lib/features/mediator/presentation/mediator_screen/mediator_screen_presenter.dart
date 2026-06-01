part of 'mediator_screen.dart';

class MediatorScreenPresenter extends StatefulWidget {
  final String sessionId;

  static MediatorScreenPresenterState of(BuildContext context) {
    return context.findAncestorStateOfType<MediatorScreenPresenterState>()!;
  }

  final Widget child;

  const MediatorScreenPresenter({
    required this.sessionId,
    required this.child,
    super.key,
  });

  @override
  State<MediatorScreenPresenter> createState() => MediatorScreenPresenterState();
}

class MediatorScreenPresenterState extends State<MediatorScreenPresenter> {
  final TextEditingController controller = TextEditingController();

  bool get canSubmit => controller.text.trim().characters.length >= 3;

  void submitCity() {
    if (!canSubmit) {
      return;
    }
    final value = controller.text;
    context.read<MediatorBloc>().add(
      MediatorCitySubmitted(sessionId: widget.sessionId, cityName: value),
    );
    controller.clear();
  }

  String rejectReasonText(MediatorTurn turn) {
    switch (turn.rejectReason) {
      case MediatorTurnRejectReason.emptyInput:
        return 'Введите название населенного пункта';
      case MediatorTurnRejectReason.notFound:
        return 'Населенный пункт не найден в базе';
      case MediatorTurnRejectReason.alreadyUsed:
        final duplicateName = turn.duplicateMatchedName;
        final actualName = turn.locality?.matchedName;
        if (duplicateName != null && actualName != null && duplicateName.toLowerCase() != actualName.toLowerCase()) {
          return 'Этот населенный пункт уже использован как "$duplicateName". '
              'Актуальное название: "$actualName".';
        }
        if (duplicateName != null) {
          return 'Этот населенный пункт уже использован: "$duplicateName".';
        }
        return 'Этот населенный пункт уже использован';
      case MediatorTurnRejectReason.wrongStartLetter:
        final expected = turn.expectedStartLetter;
        if (expected == null) {
          return 'Неверная первая буква';
        }
        return 'Нужно начать с буквы "$expected"';
      case MediatorTurnRejectReason.typeNotAllowed:
        final type = turn.locality?.cityType;
        return 'Тип "$type" не засчитывается по текущим настройкам';
      case MediatorTurnRejectReason.oldNameNotAllowed:
        return 'Исторические названия отключены в правилах';
      case MediatorTurnRejectReason.belowMinPopulation:
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

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
    final lang = getIt<LanguageBloc>().state.language;
    switch (turn.rejectReason) {
      case MediatorTurnRejectReason.emptyInput:
        return AppGlossary.rejectEmptyInput.translate();
      case MediatorTurnRejectReason.notFound:
        return AppGlossary.rejectNotFound.translate();
      case MediatorTurnRejectReason.alreadyUsed:
        final duplicateName = turn.duplicateMatchedName;
        final baseMsg = AppGlossary.rejectAlreadyUsed.translate();
        if (duplicateName != null) {
          return '$baseMsg: "$duplicateName".';
        }
        return baseMsg;
      case MediatorTurnRejectReason.wrongStartLetter:
        final expected = turn.expectedStartLetter;
        if (expected == null) {
          return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', '?');
        }
        return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', expected);
      case MediatorTurnRejectReason.typeNotAllowed:
        final type = turn.locality?.cityType;
        final translated = type != null ? translateCityType(type) : '?';
        return AppGlossary.rejectTypeNotAllowed.translate().replaceAll('{type}', translated);
      case MediatorTurnRejectReason.oldNameNotAllowed:
        return AppGlossary.rejectOldNameNotAllowed.translate();
      case MediatorTurnRejectReason.belowMinPopulation:
        return AppGlossary.rejectBelowMinPopulation.translate();
      case MediatorTurnRejectReason.countryNotAllowed:
        final locality = turn.locality;
        if (locality == null || locality.countryCode.isEmpty) {
          return AppGlossary.rejectCountryNotAllowed.translate().replaceAll('{country}', '?');
        }
        final countryName = countryNames[locality.countryCode.toLowerCase()]?[lang] ?? locality.country;
        return AppGlossary.rejectCountryNotAllowed.translate().replaceAll('{country}', countryName);
      case null:
        return AppGlossary.rejectDeclined.translate();
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

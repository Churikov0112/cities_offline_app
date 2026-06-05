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
    final lang = getIt<LanguageBloc>().state.language;
    switch (turn.rejectReason) {
      case AiTurnRejectReason.emptyInput:
        return AppGlossary.rejectEmptyInput.translate();
      case AiTurnRejectReason.notFound:
        return AppGlossary.rejectNotFound.translate();
      case AiTurnRejectReason.alreadyUsed:
        return AppGlossary.rejectAlreadyUsed.translate();
      case AiTurnRejectReason.wrongStartLetter:
        final expected = turn.expectedStartLetter;
        if (expected == null || expected.isEmpty) {
          return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', '?');
        }
        return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', expected);
      case AiTurnRejectReason.typeNotAllowed:
        final type = turn.locality?.cityType;
        final translated = type != null ? translateCityType(type) : '?';
        return AppGlossary.rejectTypeNotAllowed.translate().replaceAll('{type}', translated);
      case AiTurnRejectReason.oldNameNotAllowed:
        return AppGlossary.rejectOldNameNotAllowed.translate();
      case AiTurnRejectReason.belowMinPopulation:
        return AppGlossary.rejectBelowMinPopulation.translate();
      case AiTurnRejectReason.countryNotAllowed:
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

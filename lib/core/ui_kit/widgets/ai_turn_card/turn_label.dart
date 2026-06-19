import 'package:flutter/material.dart';
import 'package:cities_offline_app/services/localization/translator.dart';

class AiTurnLabel extends StatelessWidget {
  final bool isAi;

  const AiTurnLabel({super.key, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Translator(
      termin: isAi ? AppGlossary.ai : AppGlossary.player,
      builder: (text) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isAi ? Colors.deepPurple : Colors.blueGrey,
        ),
      ),
    );
  }
}

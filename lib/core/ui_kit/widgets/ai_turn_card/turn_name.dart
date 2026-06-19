import 'package:flutter/material.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_turn.dart';

class AiTurnName extends StatelessWidget {
  final AiTurn turn;

  const AiTurnName({super.key, required this.turn});

  @override
  Widget build(BuildContext context) {
    final text = turn.locality?.matchedName ?? turn.input;
    if (turn.status != AiTurnStatus.accepted || text.isEmpty) {
      return Text(text);
    }

    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }
}

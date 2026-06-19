import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_turn.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'turn_label.dart';
import 'turn_name.dart';
import 'locality_details.dart';

class AiTurnCard extends StatefulWidget {
  final AiTurn turn;
  final String rejectReasonText;

  const AiTurnCard({
    super.key,
    required this.turn,
    required this.rejectReasonText,
  });

  @override
  State<AiTurnCard> createState() => _AiTurnCardState();
}

class _AiTurnCardState extends State<AiTurnCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.turn.locality != null;
    final isAi = widget.turn.actor == AiTurnActor.ai;

    return Card(
      child: InkWell(
        onTap: canExpand ? _toggleExpanded : null,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: widget.turn.input));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Translator(
                termin: AppGlossary.copied,
                builder: (text) => Text(text),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiTurnLabel(isAi: isAi),
                        const SizedBox(height: 6),
                        AiTurnName(turn: widget.turn),
                        if (widget.turn.status == AiTurnStatus.rejected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(widget.rejectReasonText, style: const TextStyle(color: Colors.redAccent)),
                          ),
                        if (widget.turn.status == AiTurnStatus.surrendered)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Translator(
                              termin: AppGlossary.iSurrender,
                              builder: (text) => Text(text),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (canExpand)
                    IconButton(
                      onPressed: _toggleExpanded,
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded && canExpand
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LocalityDetails(locality: widget.turn.locality!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}

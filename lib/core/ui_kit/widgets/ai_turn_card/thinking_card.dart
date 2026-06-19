import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cities_offline_app/services/localization/translator.dart';

class AiThinkingCard extends StatefulWidget {
  const AiThinkingCard({super.key});

  @override
  State<AiThinkingCard> createState() => _AiThinkingCardState();
}

class _AiThinkingCardState extends State<AiThinkingCard> {
  static const _frames = ['', '.', '..', '...'];
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const SizedBox(width: 28, child: Icon(Icons.smart_toy_outlined, size: 18)),
            const SizedBox(width: 8),
            Translator(
              termin: AppGlossary.thinking,
              builder: (text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                _frames[_index],
                key: ValueKey(_index),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

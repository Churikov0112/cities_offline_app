import 'dart:async';
import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback? onTap;
  final bool compact;

  const MicButton({
    required this.isListening,
    super.key,
    this.isProcessing = false,
    this.onTap,
    this.compact = false,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _thinkingTimer;
  int _thinkingDot = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.isProcessing && !oldWidget.isProcessing) {
      _thinkingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _thinkingDot = (_thinkingDot + 1) % 4);
      });
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _thinkingTimer?.cancel();
      _thinkingTimer = null;
      _thinkingDot = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _thinkingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _compactMic();
    }
    return _fullMic();
  }

  Widget _fullMic() {
    const size = 120.0;
    const iconSize = 56.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.isListening ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening ? Colors.red : Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: widget.isProcessing
                    ? Text(
                        '...${'.' * _thinkingDot}',
                        style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      )
                    : Icon(
                        widget.isListening ? Icons.mic : Icons.mic_none,
                        size: iconSize,
                        color: widget.isListening ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _compactMic() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isListening ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: IconButton(
            onPressed: widget.onTap,
            icon: widget.isProcessing
                ? Text(
                    '...${'.' * _thinkingDot}',
                    style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  )
                : Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none,
                    color: widget.isListening ? Colors.red : null,
                  ),
          ),
        );
      },
    );
  }
}

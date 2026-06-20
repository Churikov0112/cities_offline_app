import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/voice_cubit.dart';

class VoiceStatusBanner extends StatelessWidget {
  const VoiceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceCubit, VoiceState>(
      builder: (context, state) {
        if (state.phase == VoicePhase.idle && state.statusText.isEmpty) {
          return const SizedBox.shrink();
        }

        final text = state.statusText.isNotEmpty
            ? state.statusText
            : _defaultText(state.phase);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _backgroundColor(state.phase),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(state.phase),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _icon(VoicePhase phase) {
    return switch (phase) {
      VoicePhase.speaking => const Icon(Icons.volume_up, color: Colors.white, size: 20),
      VoicePhase.listening => const Icon(Icons.mic, color: Colors.white, size: 20),
      VoicePhase.processing => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      VoicePhase.idle => const SizedBox.shrink(),
    };
  }

  Color _backgroundColor(VoicePhase phase) {
    return switch (phase) {
      VoicePhase.speaking => Colors.blue,
      VoicePhase.listening => Colors.red,
      VoicePhase.processing => Colors.orange,
      VoicePhase.idle => const Color(0xFF37474F),
    };
  }

  String _defaultText(VoicePhase phase) {
    return switch (phase) {
      VoicePhase.speaking => '...',
      VoicePhase.listening => '...',
      VoicePhase.processing => '...',
      VoicePhase.idle => '',
    };
  }
}

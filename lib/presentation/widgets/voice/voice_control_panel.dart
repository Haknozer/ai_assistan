import 'package:flutter/material.dart';

import 'voice_types.dart';

class VoiceControlPanel extends StatelessWidget {
  final VoiceStep step;
  final int currentDb;
  final VoidCallback onToggleRecording;

  const VoiceControlPanel({
    super.key,
    required this.step,
    required this.currentDb,
    required this.onToggleRecording,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = step == VoiceStep.listening;
    final isThinking = step == VoiceStep.thinking;
    final isSpeaking = step == VoiceStep.speaking;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onToggleRecording,
                icon: Icon(
                  isListening ? Icons.stop_circle_outlined : Icons.mic_outlined,
                ),
                label: Text(
                  isListening
                      ? 'Kaydı bitir'
                      : isThinking
                          ? 'Düşünüyor...'
                          : isSpeaking
                              ? 'Konuşuyor...'
                              : 'Bas-Konuş',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isListening ? Colors.red : null,
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VoiceStatusRow(step: step),
          if (isListening)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Gürültü seviyesi: $currentDb dB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class VoiceStatusRow extends StatelessWidget {
  final VoiceStep step;
  const VoiceStatusRow({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;
    switch (step) {
      case VoiceStep.listening:
        label = 'Dinliyor...';
        icon = Icons.hearing;
        color = Colors.orange;
        break;
      case VoiceStep.thinking:
        label = 'Düşünüyor...';
        icon = Icons.autorenew;
        color = Colors.blue;
        break;
      case VoiceStep.speaking:
        label = 'Konuşuyor...';
        icon = Icons.volume_up;
        color = Colors.green;
        break;
      case VoiceStep.error:
        label = 'Hata';
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case VoiceStep.idle:
        label = 'Hazır';
        icon = Icons.mic_none;
        color = Colors.grey;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


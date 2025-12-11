import 'package:flutter/material.dart';

class VoiceBubbles extends StatelessWidget {
  final String transcript;
  final String reply;

  const VoiceBubbles({
    super.key,
    required this.transcript,
    required this.reply,
  });

  @override
  Widget build(BuildContext context) {
    final userColor = Theme.of(context).colorScheme.primaryContainer;
    final assistantColor = Theme.of(context).colorScheme.secondaryContainer;

    return Column(
      children: [
        if (transcript.isNotEmpty)
          _Bubble(
            title: 'Sen',
            text: transcript,
            icon: Icons.person_outline,
            color: userColor,
          ),
        if (reply.isNotEmpty)
          _Bubble(
            title: 'Asistan',
            text: reply,
            icon: Icons.smart_toy_outlined,
            color: assistantColor,
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _Bubble({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }
}


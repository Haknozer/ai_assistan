import 'package:flutter/material.dart';

class VoiceSheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const VoiceSheetHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mic_outlined),
        const SizedBox(width: 8),
        const Text(
          'Sesli Asistan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton(
          onPressed: onClose,
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}


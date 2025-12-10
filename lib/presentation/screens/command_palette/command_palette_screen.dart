// Bu ekran artık popup’a taşındı. Yer tutucu olarak boş bir widget.
import 'package:flutter/material.dart';

class CommandPaletteScreen extends StatelessWidget {
  const CommandPaletteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: SizedBox.shrink()),
    );
  }
}


import 'package:flutter/material.dart';

class CommandPaletteEmptyResult extends StatelessWidget {
  const CommandPaletteEmptyResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          const Text('Sonuç bulunamadı'),
          const SizedBox(height: 4),
          Text(
            'Arama terimini değiştir veya kısayollara göz at',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}


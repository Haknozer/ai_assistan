import 'package:flutter/material.dart';

/// Öneri chip listesi widget'ı
class SuggestionChipList extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;

  const SuggestionChipList({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions.map((text) => _buildSuggestionChip(context, text)).toList(),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => onTap(text),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    );
  }
}


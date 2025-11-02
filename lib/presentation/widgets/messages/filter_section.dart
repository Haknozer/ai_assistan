import 'package:flutter/material.dart';

/// Filtre chip'leri bölümü
class FilterSection extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final List<String> filters;

  const FilterSection({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.filters = const ['Tümü', 'Okunmamış', 'Email', 'Slack', 'Teams', 'WhatsApp'],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Colors.blue.withValues(alpha: 0.2),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.blue.shade700
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


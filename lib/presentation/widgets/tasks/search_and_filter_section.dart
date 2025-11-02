import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/tasks/utils/task_filter.dart';

/// Arama ve filtreleme bölümü widget'ı
class SearchAndFilterSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final bool isDesktop;

  const SearchAndFilterSection({
    super.key,
    required this.onSearchChanged,
    required this.currentFilter,
    required this.onFilterChanged,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSearchField(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFilterChips(context),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildSearchField(context),
          const SizedBox(height: 12),
          _buildFilterChips(context),
        ],
      );
    }
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Görev arama...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.getCardColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.getBorderColor(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.getBorderColor(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
      onChanged: onSearchChanged,
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              backgroundColor: AppColors.getCardColor(context),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppColors.getPrimaryTextColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : AppColors.getBorderColor(context),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


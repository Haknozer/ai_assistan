import 'package:flutter/material.dart';
import '../../../utils/responsive_utils.dart';
import '../../screens/settings/data/settings_data.dart';

/// Settings kategori butonları widget'ı
class SettingsCategoryButtons extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onCategoryTap;

  const SettingsCategoryButtons({
    super.key,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: ResponsiveUtils.isDesktop(context)
            ? _buildDesktopButtons(context)
            : _buildMobileButtons(context),
      ),
    );
  }

  Widget _buildDesktopButtons(BuildContext context) {
    return Row(
      children: SettingsData.categories.map((category) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildSettingsButton(context, category),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSettingsButton(context, SettingsData.categories[0]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSettingsButton(context, SettingsData.categories[1]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSettingsButton(context, SettingsData.categories[2]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSettingsButton(context, SettingsData.categories[3]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context, String title) {
    final isSelected = selectedCategory == title;

    return InkWell(
      onTap: () => onCategoryTap(title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


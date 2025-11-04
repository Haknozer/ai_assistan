import 'package:flutter/material.dart';
import '../../screens/settings/utils/settings_utils.dart';
import 'integrations_item_detailed.dart';

/// Entegrasyonlar kategorisi kartı - Genişletilebilir
class IntegrationsCategoryCard extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> integrations;
  final String? selectedCategory;
  final Function(String) onCategoryTap;
  final Function(String, bool) onIntegrationTap;

  const IntegrationsCategoryCard({
    super.key,
    required this.category,
    required this.integrations,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.onIntegrationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedCategory == category;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onCategoryTap(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori Başlığı
              _buildCategoryHeader(context, isSelected),

              // Entegrasyonlar (genişletilmiş olduğunda)
              if (isSelected) ...[
                const SizedBox(height: 16),
                ...integrations.map((integration) {
                  return IntegrationsItemDetailed(
                    integration: integration,
                    onTap: onIntegrationTap,
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, bool isSelected) {
    return Row(
      children: [
        Icon(
          SettingsUtils.getCategoryIcon(category),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        Icon(
          isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}


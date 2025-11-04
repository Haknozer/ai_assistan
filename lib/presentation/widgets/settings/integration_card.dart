import 'package:flutter/material.dart';
import '../../screens/settings/utils/settings_utils.dart';
import 'integration_item.dart';

/// Entegrasyon kategorisi kartı widget'ı
class IntegrationCard extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> integrations;
  final Function(String, bool) onIntegrationTap;

  const IntegrationCard({
    super.key,
    required this.category,
    required this.integrations,
    required this.onIntegrationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori Başlığı
            _buildCategoryHeader(context),
            const SizedBox(height: 16),

            // Entegrasyonlar
            ...integrations.map((integration) {
              return IntegrationItem(
                integration: integration,
                categoryIcon: SettingsUtils.getCategoryIcon(category),
                onTap: onIntegrationTap,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İkon ve Başlık (aynı hizada)
        Row(
          children: [
            Icon(
              SettingsUtils.getCategoryIcon(category),
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        // Küçük Başlık (altında)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            SettingsUtils.getCategoryDescription(category),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}


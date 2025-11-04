import 'package:flutter/material.dart';
import '../../screens/settings/data/settings_data.dart';
import 'notification_category_item.dart';

/// Bildirimler kartı widget'ı
class NotificationsCard extends StatelessWidget {
  final Map<String, bool> notificationStates;
  final Function(String, bool) onNotificationChanged;

  const NotificationsCard({
    super.key,
    required this.notificationStates,
    required this.onNotificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori Başlığı
            _buildHeader(context),
            const SizedBox(height: 24),

            // Bildirim Listesi
            ...SettingsData.notificationCategories.entries.map((entry) {
              return NotificationCategoryItem(
                category: entry.key,
                title: entry.value,
                isEnabled: notificationStates[entry.value] ?? false,
                onChanged: (value) => onNotificationChanged(entry.value, value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İkon ve Başlık (aynı hizada)
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Bildirim Tercihleri',
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
            'Hangi bildirimleri almak istediğinizi seçin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}


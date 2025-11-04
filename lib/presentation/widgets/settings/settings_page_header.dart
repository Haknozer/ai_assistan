import 'package:flutter/material.dart';

/// Ayarlar sayfası başlığı widget'ı
class SettingsPageHeader extends StatelessWidget {
  final bool isDesktop;

  const SettingsPageHeader({
    super.key,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildHeaderContent(context);
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayarlar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uygulamanızı kişiselleştirin ve entegrasyonları yönetin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}
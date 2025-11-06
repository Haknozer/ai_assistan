import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/theme_provider.dart';

/// Görünüm ayarları kartı widget'ı
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            const SizedBox(height: 16),

            // Karanlık Mod
            _buildDarkModeSection(context, ref, isDarkMode),
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
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Görünüm Ayarları',
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
            'Uygulamanın görünümünü özelleştirin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkModeSection(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Karanlık Mod',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Karanlık tema kullan',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Switch(
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Karanlık mod ${value ? "açık" : "kapalı"}')),
                );
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

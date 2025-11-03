import 'package:flutter/material.dart';

/// Analitik sayfası başlığı widget'ı
class AnalyticsPageHeader extends StatelessWidget {
  final VoidCallback onDownloadPDF;
  final bool isDesktop;

  const AnalyticsPageHeader({
    super.key,
    required this.onDownloadPDF,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          _buildHeaderContent(context),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onDownloadPDF,
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('PDF Raporu İndir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildHeaderContent(context)),
          IconButton.filled(
            onPressed: onDownloadPDF,
            icon: const Icon(Icons.picture_as_pdf),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(40, 40),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analitik & Raporlar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          'Detaylı istatistikler ve performans analizi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

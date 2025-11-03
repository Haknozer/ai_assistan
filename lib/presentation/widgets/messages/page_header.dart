import 'package:flutter/material.dart';
import '../unread_badge.dart';

/// Sayfa başlığı widget'ı
class PageHeader extends StatelessWidget {
  final int unreadCount;

  const PageHeader({
    super.key,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birleşik Gelen Kutusu',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tüm platformlarınızdan mesajları tek yerden yönetin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
        UnreadBadge(count: unreadCount),
      ],
    );
  }
}

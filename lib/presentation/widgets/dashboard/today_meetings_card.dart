import 'package:flutter/material.dart';

class TodayMeetingsCard extends StatelessWidget {
  const TodayMeetingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bugünkü Toplantılar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _MeetingItem(
                  title: 'Tasarım Toplantısı',
                  time: '10:00',
                  platform: 'Zoom',
                  timeRemaining: '2 saat kaldı',
                ),
                _MeetingItem(
                  title: 'Müşteri Görüşmesi',
                  time: '14:00',
                  platform: 'Toplantı Odası - A201',
                  timeRemaining: '6 saat kaldı',
                ),
                _MeetingItem(
                  title: 'Sprint Planlama',
                  time: '16:30',
                  platform: 'Google Meet',
                  timeRemaining: '8.5 saat kaldı',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingItem extends StatelessWidget {
  final String title;
  final String time;
  final String platform;
  final String timeRemaining;

  const _MeetingItem({
    required this.title,
    required this.time,
    required this.platform,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Saat ve Kalan Süre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Saat
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              // Kalan Süre
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timeRemaining,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Platform
          Row(
            children: [
              Icon(
                _getPlatformIcon(platform),
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  platform,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    final platformLower = platform.toLowerCase();
    if (platformLower.contains('zoom')) {
      return Icons.video_call;
    } else if (platformLower.contains('teams')) {
      return Icons.groups;
    } else if (platformLower.contains('meet')) {
      return Icons.videocam;
    } else if (platformLower.contains('oda') || platformLower.contains('room')) {
      return Icons.meeting_room;
    }
    return Icons.place;
  }
}


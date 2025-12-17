import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/calendar_event.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../features/calendar/providers/calendar_provider.dart';
import '../../../models/calendar_account.dart';

class TodayMeetingsCard extends ConsumerWidget {
  const TodayMeetingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Bugünün zaman aralığı
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Calendar hesaplarını al (Google / Outlook)
    final accountsAsync = ref.watch(
      calendarAccountsProvider(CalendarAccountsParams(userId: currentUser.id)),
    );

    return accountsAsync.when(
      loading: () => _buildContainer(
        context,
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => _buildContainer(
        context,
        Expanded(
          child: Center(
            child: Text(
              'Calendar hesapları yüklenemedi: $e',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (accounts) {
        // Google ve Outlook tokenlarını çıkar
        String? googleToken;
        String? outlookToken;
        try {
          googleToken = accounts
              .firstWhere(
                (a) => a.provider == CalendarProvider.google && a.isActive,
              )
              .accessToken;
        } catch (_) {
          googleToken = null;
        }
        try {
          outlookToken = accounts
              .firstWhere(
                (a) => a.provider == CalendarProvider.outlook && a.isActive,
              )
              .accessToken;
        } catch (_) {
          outlookToken = null;
        }

        final calendarRepo = ref.watch(calendarRepositoryProvider);

        return FutureBuilder<List<CalendarEvent>>(
          future: calendarRepo.getAllCombinedEvents(
            calendarId: 'primary',
            timeMin: todayStart,
            timeMax: todayEnd,
            googleAccessToken: googleToken,
            outlookAccessToken: outlookToken,
            userId: currentUser.id,
          ),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final error = snapshot.error;
            final events = snapshot.data ?? [];

            // Sadece bugünkü toplantı türündeki event'ler
            final meetings = events.where((e) => e.eventType == EventType.meeting).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            if (isLoading) {
              return _buildContainer(
                context,
                const Expanded(child: Center(child: CircularProgressIndicator())),
              );
            }

            if (error != null) {
              return _buildContainer(
                context,
                Expanded(
                  child: Center(
                    child: Text(
                      'Toplantılar yüklenemedi: $error',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (meetings.isEmpty) {
              return _buildContainer(
                context,
                Expanded(
                  child: Center(
                    child: Text(
                      'Bugün için toplantı bulunmuyor.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              );
            }

            return _buildContainer(
              context,
              Expanded(
                child: ListView.builder(
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final event = meetings[index];
                    return _MeetingItem.fromEvent(event);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, Widget content) {
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
          content,
        ],
      ),
    );
  }
}

class _MeetingItem extends StatelessWidget {
  final CalendarEvent event;

  const _MeetingItem({
    required this.event,
  });

  factory _MeetingItem.fromEvent(CalendarEvent event) {
    return _MeetingItem(event: event);
  }

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
            event.title,
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
                    _formatTimeRange(event),
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
                  _formatTimeRemaining(event),
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
                _getPlatformIcon(event.location ?? ''),
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  event.location?.isNotEmpty == true ? event.location! : 'Lokasyon belirtilmemiş',
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

  String _formatTimeRange(CalendarEvent event) {
    // CalendarEvent içinde tanımlı formattedTime kullan
    return event.formattedTime;
  }

  String _formatTimeRemaining(CalendarEvent event) {
    final now = DateTime.now();
    if (event.isPast) {
      return 'Tamamlandı';
    } else if (event.isNow) {
      return 'Şu anda devam ediyor';
    } else {
      final diff = event.startTime.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours <= 0 && minutes <= 0) {
        return 'Az sonra başlayacak';
      } else if (hours <= 0) {
        return '$minutes dk kaldı';
      } else {
        return minutes == 0 ? '$hours saat kaldı' : '$hours sa $minutes dk kaldı';
      }
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/calendar_account.dart';
import '../../../models/calendar_event.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../features/calendar/providers/calendar_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_theme.dart';

/// Calendar event onay dialog'u
/// Error durumundaki event'leri kullanıcıya gösterir ve onay ister
class CalendarEventConfirmationDialog extends ConsumerWidget {
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? kategori;
  final String userMessage;
  final VoidCallback? onEventAdded;

  const CalendarEventConfirmationDialog({
    super.key,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.kategori,
    required this.userMessage,
    this.onEventAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Calendar account'ları kontrol et
    final calendarAccountsAsync = ref.watch(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser.id,
    )));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: calendarAccountsAsync.when(
          data: (accounts) {
            CalendarAccount? googleAccount;
            CalendarAccount? outlookAccount;
            
            try {
              googleAccount = accounts.firstWhere(
                (account) => account.provider == CalendarProvider.google && account.isActive,
              );
            } catch (e) {
              googleAccount = null;
            }
            
            try {
              outlookAccount = accounts.firstWhere(
                (account) => account.provider == CalendarProvider.outlook && account.isActive,
              );
            } catch (e) {
              outlookAccount = null;
            }

            final hasGoogle = googleAccount != null;
            final hasOutlook = outlookAccount != null;

            if (!hasGoogle && !hasOutlook) {
              return _buildNoCalendarConnection(context);
            }

            return _buildConfirmationContent(
              context,
              ref,
              hasGoogle: hasGoogle,
              hasOutlook: hasOutlook,
              googleAccount: hasGoogle ? googleAccount : null,
              outlookAccount: hasOutlook ? outlookAccount : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildNoCalendarConnection(context),
        ),
      ),
    );
  }

  Widget _buildNoCalendarConnection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 48,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          'Takvim Bağlantısı Gerekli',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Etkinliği takvime eklemek için Google Calendar veya Outlook Calendar bağlantısı yapmanız gerekiyor.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Tamam'),
        ),
      ],
    );
  }

  Widget _buildConfirmationContent(
    BuildContext context,
    WidgetRef ref, {
    required bool hasGoogle,
    required bool hasOutlook,
    CalendarAccount? googleAccount,
    CalendarAccount? outlookAccount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Takvime Eklenemedi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Event bilgileri
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (startTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(startTime!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hata mesajı
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calendar seçimi
        Text(
          'Hangi takvime eklemek istersiniz?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (hasGoogle)
          _buildCalendarOption(
            context,
            'Google Calendar',
            Icons.calendar_today,
            Colors.blue,
            () => _addToCalendar(context, ref, googleAccount!),
          ),
        if (hasGoogle && hasOutlook) const SizedBox(height: 8),
        if (hasOutlook)
          _buildCalendarOption(
            context,
            'Outlook Calendar',
            Icons.event,
            Colors.orange,
            () => _addToCalendar(context, ref, outlookAccount!),
          ),
        if (hasGoogle && hasOutlook) ...[
          const SizedBox(height: 8),
          _buildCalendarOption(
            context,
            'Her İkisine de Ekle',
            Icons.event_available,
            Colors.green,
            () => _addToBothCalendars(context, ref, googleAccount!, outlookAccount!),
          ),
        ],
        const SizedBox(height: 24),

        // Butonlar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCalendar(
    BuildContext context,
    WidgetRef ref,
    CalendarAccount account,
  ) async {
    try {
      if (account.accessToken == null || account.accessToken!.isEmpty) {
        throw Exception('Access token bulunamadı');
      }

      final calendarRepository = ref.read(calendarRepositoryProvider);
      
      // Kategori'den EventType'a çevir
      final eventType = EventType.fromCategory(kategori);
      
      await calendarRepository.createEvent(
        title: title,
        startTime: startTime ?? DateTime.now(),
        endTime: endTime ?? (startTime?.add(const Duration(hours: 1)) ?? DateTime.now().add(const Duration(hours: 1))),
        description: description,
        eventType: eventType,
        accessToken: account.accessToken!,
        provider: account.provider,
        userId: account.userId,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account.provider.displayName} takvimine eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Event eklendikten sonra callback'i çağır (UI'ı güncellemek için)
        onEventAdded?.call();
      }
    } catch (e) {
      AppLogger.error(
        'Calendar event eklenirken hata',
        tag: 'CalendarEventConfirmation',
        error: e,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToBothCalendars(
    BuildContext context,
    WidgetRef ref,
    CalendarAccount googleAccount,
    CalendarAccount outlookAccount,
  ) async {
    try {
      // Google'a ekle
      await _addToCalendar(context, ref, googleAccount);
      // Outlook'a ekle
      await _addToCalendar(context, ref, outlookAccount);
    } catch (e) {
      AppLogger.error(
        'Her iki takvime eklenirken hata',
        tag: 'CalendarEventConfirmation',
        error: e,
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}


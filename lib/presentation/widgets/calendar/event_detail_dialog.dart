import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/calendar_event.dart';
import '../../../models/calendar_account.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../features/calendar/providers/calendar_provider.dart';
import '../../../core/utils/html_stripper.dart';
import '../../screens/calendar/utils/calendar_utils.dart';
import 'package:intl/intl.dart';

/// Event detay ve düzenleme dialog'u
class EventDetailDialog extends ConsumerStatefulWidget {
  final CalendarEvent event;
  final List<CalendarEvent> allEvents; // Tüm event listesi (duplicate kontrolü için)
  final VoidCallback? onEventUpdated;
  final VoidCallback? onEventDeleted;

  const EventDetailDialog({
    super.key,
    required this.event,
    required this.allEvents,
    this.onEventUpdated,
    this.onEventDeleted,
  });

  @override
  ConsumerState<EventDetailDialog> createState() => _EventDetailDialogState();
}

class _EventDetailDialogState extends ConsumerState<EventDetailDialog> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  EventType? _eventType;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description ?? '';
    _locationController.text = widget.event.location ?? '';
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _eventType = widget.event.eventType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Aynı event'in duplicate versiyonlarını bul (hem Google hem Outlook'ta varsa)
  List<CalendarEvent> _findDuplicateEvents() {
    final duplicates = <CalendarEvent>[widget.event];
    
    for (final otherEvent in widget.allEvents) {
      if (otherEvent.id == widget.event.id) continue; // Aynı event
      
      // Başlık + saat aynı mı?
      final sameTitleAndTime = otherEvent.title.toLowerCase().trim() == widget.event.title.toLowerCase().trim() &&
          otherEvent.startTime.year == widget.event.startTime.year &&
          otherEvent.startTime.month == widget.event.startTime.month &&
          otherEvent.startTime.day == widget.event.startTime.day &&
          otherEvent.startTime.hour == widget.event.startTime.hour;
      
      // Veya detay + saat aynı mı?
      final sameDescriptionAndTime = (otherEvent.description ?? '').isNotEmpty &&
          (widget.event.description ?? '').isNotEmpty &&
          otherEvent.description?.toLowerCase().trim() == widget.event.description?.toLowerCase().trim() &&
          otherEvent.startTime.year == widget.event.startTime.year &&
          otherEvent.startTime.month == widget.event.startTime.month &&
          otherEvent.startTime.day == widget.event.startTime.day &&
          otherEvent.startTime.hour == widget.event.startTime.hour;
      
      if (sameTitleAndTime || sameDescriptionAndTime) {
        duplicates.add(otherEvent);
      }
    }
    
    return duplicates;
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık zorunludur')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlangıç ve bitiş zamanı zorunludur')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş zamanı başlangıç zamanından önce olamaz')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Duplicate event'leri bul
      final duplicateEvents = _findDuplicateEvents();
      
      // Event'in source'una göre calendar account bul
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
        userId: currentUser.id,
      )));
      
      final calendarAccounts = calendarAccountsAsync.value ?? [];
      if (calendarAccounts.isEmpty) {
        throw Exception('Calendar hesabı bulunamadı');
      }

      final repository = ref.read(calendarRepositoryProvider);
      
      // Tüm duplicate event'leri paralel olarak güncelle (hem Google hem Outlook'ta varsa aynı anda)
      final updateFutures = <Future>[];
      
      for (final duplicateEvent in duplicateEvents) {
        CalendarAccount? account;
        
        if (duplicateEvent.source == EventSource.google) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.google && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        } else if (duplicateEvent.source == EventSource.outlook) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.outlook && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        }

        if (account == null || account.accessToken == null || account.accessToken!.isEmpty) {
          continue; // Bu source için account yoksa atla
        }

        // External ID kullan (Google/Outlook event ID)
        final eventId = duplicateEvent.externalId ?? duplicateEvent.id?.toString() ?? '';
        if (eventId.isEmpty) {
          continue; // Event ID yoksa atla
        }

        // Paralel güncelleme için future ekle
        final accountProvider = account.provider;
        final accountUserId = account.userId;
        updateFutures.add(
          repository.updateEvent(
            eventId: eventId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            location: _locationController.text.trim().isEmpty 
                ? null 
                : _locationController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            eventType: _eventType,
            calendarId: 'primary',
            accessToken: account.accessToken!,
            provider: accountProvider,
            userId: accountUserId,
          ).catchError((e) {
            debugPrint('Event güncelleme hatası ($accountProvider): $e');
            // Bir calendar'da hata olsa bile diğerini güncellemeye devam et
            // Hata durumunda null döndür (Future.wait için)
            return CalendarEvent(
              userId: accountUserId,
              title: '',
              startTime: DateTime.now(),
              endTime: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }),
        );
      }
      
      // Tüm güncelleme işlemlerini paralel olarak bekle
      await Future.wait(updateFutures);

      if (mounted) {
        // Önce callback'i çağır (provider'ı refresh et) - dialog kapanmadan önce
        widget.onEventUpdated?.call();
        
        // Kısa bir gecikme ile dialog'u kapat (provider refresh'in tamamlanması için)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Etkinlik güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: const Text('Bu etkinliği silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Duplicate event'leri bul
      final duplicateEvents = _findDuplicateEvents();
      
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
        userId: currentUser.id,
      )));
      
      final calendarAccounts = calendarAccountsAsync.value ?? [];
      if (calendarAccounts.isEmpty) {
        throw Exception('Calendar hesabı bulunamadı');
      }

      final repository = ref.read(calendarRepositoryProvider);
      
      // Tüm duplicate event'leri paralel olarak sil (hem Google hem Outlook'ta varsa aynı anda)
      final deleteFutures = <Future>[];
      
      for (final duplicateEvent in duplicateEvents) {
        CalendarAccount? account;
        
        if (duplicateEvent.source == EventSource.google) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.google && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        } else if (duplicateEvent.source == EventSource.outlook) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.outlook && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        }

        if (account == null || account.accessToken == null || account.accessToken!.isEmpty) {
          continue; // Bu source için account yoksa atla
        }

        final eventId = duplicateEvent.externalId ?? duplicateEvent.id?.toString() ?? '';
        if (eventId.isEmpty) {
          continue; // Event ID yoksa atla
        }

        // Paralel silme için future ekle
        final accountProvider = account.provider; // Null check için
        deleteFutures.add(
          repository.deleteEvent(
            eventId: eventId,
            calendarId: 'primary',
            accessToken: account.accessToken!,
            provider: accountProvider,
          ).catchError((e) {
            debugPrint('Event silme hatası ($accountProvider): $e');
            // Bir calendar'da hata olsa bile diğerini silmeye devam et
          }),
        );
      }
      
      // Tüm silme işlemlerini paralel olarak bekle
      await Future.wait(deleteFutures);

      if (mounted) {
        // Önce callback'i çağır (provider'ı invalidate et) - dialog kapanmadan önce
        widget.onEventDeleted?.call();
        
        // Kısa bir gecikme ile dialog'u kapat (provider refresh'in başlaması için)
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Etkinlik silindi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      // End time'ı da otomatik ayarla (eğer end time yoksa veya start time'dan önceyse)
      if (_endTime == null || _endTime!.isBefore(_startTime!)) {
        _endTime = _startTime!.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce başlangıç zamanını seçin')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime!,
      firstDate: _startTime!,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? _startTime!.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final selectedEndTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    if (selectedEndTime.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş zamanı başlangıç zamanından önce olamaz')),
      );
      return;
    }

    setState(() {
      _endTime = selectedEndTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = CalendarUtils.getEventTypeColor(widget.event.eventType);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CalendarUtils.getEventTypeIcon(widget.event.eventType),
                    color: eventColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Etkinliği Düzenle' : 'Etkinlik Detayları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _initializeForm(); // Reset form
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isEditing ? _buildEditForm() : _buildDetailView(context, eventColor),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isEditing) ...[
                    TextButton(
                      onPressed: _isSaving ? null : () {
                        setState(() {
                          _isEditing = false;
                          _initializeForm();
                        });
                      },
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEvent,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: _isDeleting ? null : _deleteEvent,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete, size: 18),
                      label: const Text('Sil'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Düzenle'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Color eventColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Text(
          widget.event.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Zaman
        _buildDetailRow(
          icon: Icons.access_time,
          label: 'Zaman',
          value: '${CalendarUtils.formatDateTime(widget.event.startTime)} - ${CalendarUtils.formatTime(widget.event.endTime)}',
        ),

        // Süre
        _buildDetailRow(
          icon: Icons.schedule,
          label: 'Süre',
          value: CalendarUtils.calculateDuration(widget.event.startTime, widget.event.endTime),
        ),

        // Lokasyon
        if (widget.event.location != null && widget.event.location!.isNotEmpty)
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Lokasyon',
            value: widget.event.location!,
          ),

        // Açıklama
        if (widget.event.description != null && widget.event.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Açıklama',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            HtmlStripper.cleanIfNeeded(widget.event.description!),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],

        // Kaynak (duplicate varsa tüm source'ları göster)
        const SizedBox(height: 16),
        Row(
          children: [
            // Tüm source'ları göster (duplicate varsa)
            ..._findDuplicateEvents().map((event) {
              final color = CalendarUtils.getEventSourceColor(event.source);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CalendarUtils.getEventSourceIcon(event.source),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.source == EventSource.google
                          ? 'Google'
                          : event.source == EventSource.outlook
                              ? 'Outlook'
                              : 'Manuel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Başlık *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Başlangıç zamanı
        InkWell(
          onTap: _selectStartTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Başlangıç Zamanı *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _startTime != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(_startTime!)
                  : 'Seçin',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bitiş zamanı
        InkWell(
          onTap: _selectEndTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Bitiş Zamanı *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _endTime != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(_endTime!)
                  : 'Seçin',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lokasyon
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Lokasyon',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),

        // Açıklama
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Event Type
        DropdownButtonFormField<EventType>(
          value: _eventType,
          decoration: const InputDecoration(
            labelText: 'Etkinlik Türü',
            border: OutlineInputBorder(),
          ),
          items: EventType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getEventTypeName(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _eventType = value;
            });
          },
        ),
      ],
    );
  }

  String _getEventTypeName(EventType type) {
    switch (type) {
      case EventType.meeting:
        return 'Toplantı';
      case EventType.appointment:
        return 'Randevu';
      case EventType.task:
        return 'Görev';
      case EventType.personal:
        return 'Kişisel';
      case EventType.other:
        return 'Diğer';
    }
  }
}

